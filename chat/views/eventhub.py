from flask import Blueprint, request, g, current_app, render_template
import datetime
import geventwebsocket
from gevent_zeromq import zmq
import json
import pymongo
from chat.markdown import markdown_renderer
from chat.tardis import datetime_to_unix

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
    message = None
    while True:
      events = dict(poller.poll())

      # Server -> Client
      if subscribe_socket in events:
        packed = subscribe_socket.recv()
        g.msg_unpacker.feed(packed)
        unpacked = g.msg_unpacker.unpack()
        action = unpacked["action"]
        data = unpacked["data"]
        if action == "message":
          channel = data["channel"]
          if channel in g.user["channels"]:
            websocket.send(json.dumps(unpacked))

      # Client -> Server
      if websocket.socket.fileno() in events:
        socket_data = websocket.receive()
        if socket_data is None:
          break
        socket_data = json.loads(socket_data)
        action = socket_data["action"]
        data = socket_data["data"]
        if action == "switch_channel":
          # Update channel logged in user is subscribed to
          g.user['last_selected_channel'] = data["channel"]
          g.users.save(g.user)
        if action == "publish_message":
          message = data["message"]
          channel = data["channel"]
          # we use isoformat in msgpack because it cant handle datetime objects
          time_now = datetime.datetime.utcnow()
          mongo_event_object = { "author": g.user["name"],
                                 "message": message,
                                 "channel": channel,
                                 "gravatar": g.user["gravatar"],
                                 "datetime": time_now }
          message_id = g.events.insert(mongo_event_object)
          rendered_message = render_template("chat_message.htmljinja",
                                             message=markdown_renderer.render(message),
                                             author=g.user["name"],
                                             message_id=message_id,
                                             gravatar=g.user["gravatar"],
                                             time=datetime_to_unix(time_now),
                                             merge_messages=False)
          msgpack_event_object = {"action":"message",
                                  "data":{
                                    "author": g.user["name"],
                                    "message": rendered_message,
                                    "channel": channel,
                                    "datetime": time_now.isoformat() }}
          packed = g.msg_packer.pack(msgpack_event_object)

          # -> Everyone
          push_socket.send(packed)
  except geventwebsocket.WebSocketError, e:
    print "{0} {1}".format(e.__class__.__name__, e)

  # TODO(kle): figure out how to clean up websockets left in a CLOSE_WAIT state
  push_socket.close()
  subscribe_socket.close()
  websocket.close()
  return ""
