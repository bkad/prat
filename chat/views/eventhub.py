from flask import Blueprint, request, g, current_app, render_template
import datetime
import geventwebsocket
from gevent_zeromq import zmq
import json
from chat.markdown import markdown_renderer

eventhub = Blueprint("eventhub", __name__)

@eventhub.route('')
def eventhub_client():
  if not request.environ.get('wsgi.websocket'):
    return ""
  websocket = request.environ['wsgi.websocket']
  push_socket = current_app.zmq_context.socket(zmq.PUSH)
  push_socket.connect(current_app.config["PUSH_ADDRESS"])
  subscribe_socket = current_app.zmq_context.socket(zmq.SUB)
  subscribe_socket.setsockopt(zmq.SUBSCRIBE, "")
  subscribe_socket.connect(current_app.config["SUBSCRIBE_ADDRESS"])

  poller = zmq.Poller()
  poller.register(subscribe_socket, zmq.POLLIN)
  poller.register(websocket.socket, zmq.POLLIN)

  try:
    while True:
      events = dict(poller.poll())
      if subscribe_socket in events:
        packed = subscribe_socket.recv()
        g.msg_unpacker.feed(packed)
        unpacked = g.msg_unpacker.unpack()
        websocket.send(json.dumps(unpacked))
      if websocket.socket.fileno() in events:
        message = websocket.receive()
        print message
        if message is None:
          break
        # we use isoformat in msgpack because it cant handle datetime objects
        time_now = datetime.datetime.utcnow()
        rendered_message = render_template("chat_message.htmljinja",
                                           message=markdown_renderer.render(message),
                                           author=g.user['name'])
        msgpack_event_object = { "author": g.user['name'],
                                 "message": rendered_message,
                                 "datetime": time_now.isoformat() }
        mongo_event_object = { "author": msgpack_event_object["author"],
                               "message": message,
                               "datetime": time_now }
        packed = g.msg_packer.pack(msgpack_event_object)
        g.events.insert(mongo_event_object)
        push_socket.send(packed)
  except geventwebsocket.WebSocketError, e:
    print "{0} {1}".format(e.__class__.__name__, e)

  # TODO(kle): figure out how to clean up websockets left in a CLOSE_WAIT state
  push_socket.close()
  subscribe_socket.close()
  websocket.close()
  return ""
