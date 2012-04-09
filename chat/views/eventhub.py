from flask import Blueprint, request, g, current_app
import datetime
import geventwebsocket
from gevent_zeromq import zmq
import json

eventhub = Blueprint("eventhub", __name__)

@eventhub.route('')
def eventhub_client():
  if not request.environ.get('wsgi.websocket'):
    return ""
  websocket = request.environ['wsgi.websocket']
  push_socket = g.zmq_context.socket(zmq.PUSH)
  push_socket.connect(current_app.config["PUSH_ADDRESS"])
  subscribe_socket = g.zmq_context.socket(zmq.SUB)
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
        # we use isoformat in msgpack because it cant handle datetime objects
        time_now = datetime.datetime.utcnow()
        event_object = { "author": "bkad",
                         "message": message,
                         "datetime": time_now.isoformat() }
        packed = g.msg_packer.pack(event_object)
        if message is None:
          break
        event_object["datetime"] = time_now
        g.events.insert(event_object)
        push_socket.send(packed)
  except geventwebsocket.WebSocketError, e:
    print "{0} {1}".format(e.__class__.__name__, e)

  websocket.close()
  subscribe_socket.close()
  push_socket.close()
  return ""
