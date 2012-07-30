from flask import Blueprint, request, g, current_app, render_template
import datetime
import geventwebsocket
from gevent_zeromq import zmq
import json
from chat.datastore import db, message_dict_from_event_object, find_or_create_channel
from chat.zmq_context import zmq_context
import uuid

eventhub = Blueprint("eventhub", __name__)

@eventhub.route('')
def eventhub_client():
  if not request.environ.get('wsgi.websocket'):
    return ""
  websocket = request.environ['wsgi.websocket']
  push_socket = zmq_context.socket(zmq.PUSH)
  push_socket.connect(current_app.config["PUSH_ADDRESS"])
  subscribe_socket = zmq_context.socket(zmq.SUB)
  user_channels = {}
  client_id = uuid.uuid4()

  # listen for messages that happen on channels the user is subscribed to
  for channel in g.user["channels"]:
    channel_id = str(db.channels.find_one({"name": channel})["_id"])
    user_channels[channel] = channel_id
    subscribe_socket.setsockopt(zmq.SUBSCRIBE, channel_id)

  # subscribe to events the user triggered that could affect the user's other open clients
  subscribe_socket.setsockopt_string(zmq.SUBSCRIBE, g.user["email"])

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
        message = subscribe_socket.recv()

        # the message is prepended by the channel_id (for PUB/SUB reasons)
        channel_id, packed = message.split(" ", 1)
        g.msg_unpacker.feed(packed)
        unpacked = g.msg_unpacker.unpack()
        action = unpacked["action"]
        if action in ["message", "join_channel", "leave_channel"]:
          websocket.send(json.dumps(unpacked))
        elif action in ["self_join_channel", "self_leave_channel"]:
          event_type = action.split("_")[1]
          handle_self_channel_event(client_id, websocket, unpacked["data"], event_type)

      # Client -> Server
      if websocket.socket.fileno() in events:
        socket_data = websocket.receive()
        if socket_data is None:
          break
        socket_data = json.loads(socket_data)
        action = socket_data["action"]
        data = socket_data["data"]
        if action == "switch_channel":
          handle_switch_channel(data["channel"])
        elif action == "publish_message":
          handle_publish_message(data, push_socket, user_channels)
        elif action == "join_channel":
          handle_join_channel(data["channel"], subscribe_socket, push_socket, user_channels, client_id)
  except geventwebsocket.WebSocketError, e:
    print "{0} {1}".format(e.__class__.__name__, e)

  # TODO(kle): figure out how to clean up websockets left in a CLOSE_WAIT state
  push_socket.close()
  subscribe_socket.close()
  websocket.close()
  return ""


def handle_leave_channel(channel_name, subscribe_socket, push_socket, user_channels, client_id):
  if channel_name not in user_channels:
    return

  del user_channels[channel_name]

  # unsubscribe to events happening on this channel
  subscribe_socket.setsockopt(zmq.UNSUBSCRIBE, channel_id)
  

  if channel_name in g.user["channels"]:
    g.user["channels"].remove(channel_name)
    db.users.save(g.user)

  channel = find_or_create_channel(channel_name)
  channel_id = str(channel["_id"])

  if g.user["email"] not in channel["users"]:
    return

  del channel["users"][g.user["email"]]

  db.channels.save(channel)

  leave_channel_event = {
      "action": "leave_channel",
      "data": {
        "email": g.user["email"],
      },
  }
  # alert channel subscribers to user leaving
  packed_leave_channel = g.msg_packer.pack(leave_channel_event)
  push_socket.send(" ".join(channel_id, packed_leave_channel))

  self_join_channel_event = {
      "action": "self_leave_channel",
      "data": {
        "client_id": client_id,
      },
  }
  packed_self_leave_channel = g.msg_packer.pack(self_join_channel_event)
  push_socket.send(" ".join(g.user["email"], packed_self_leave_channel))


def handle_join_channel(channel_name, subscribe_socket, push_socket, user_channels, client_id):
  if channel_name in user_channels:
    return
  channel = find_or_create_channel(channel_name)
  channel_id = str(channel["_id"])
  user_channels[channel_name] = channel_id

  # subscribe to events happening on this channel
  subscribe_socket.setsockopt(zmq.SUBSCRIBE, channel_id)
  
  if channel_name not in g.user["channels"]:
    g.user["channels"].append(channel_name)
    db.users.save(g.user)

  if g.user["email"] in channel["users"]:
    return

  channel["users"][g.user["email"]] = "active"
  db.channels.save(channel)
  join_channel_event = {
      "action": "join_channel",
      "data": {
        "email": g.user["email"],
      },
  }
  # alert channel subscribers to new user
  packed_join_channel = g.msg_packer.pack(join_channel_event)
  push_socket.send(" ".join(channel_id, packed_join_channel))

  # alert the user's other open clients of the change
  self_join_channel_event = {
      "action": "self_join_channel",
      "data": {
        "client_id": client_id,
      },
  }
  packed_self_join_channel = g.msg_packer.pack(self_join_channel_event)
  push_socket.send(" ".join(g.user["email"], packed_self_join_channel))


def handle_switch_channel(channel_name):
  # Update channel logged in user is subscribed to
  g.user['last_selected_channel'] = channel_name
  db.users.save(g.user)


def handle_publish_message(data, push_socket, user_channels):
  message = data["message"]
  channel = data["channel"]
  author = g.user["name"]
  email = g.user["email"]
  gravatar = g.user["gravatar"]
  # we use isoformat in msgpack because it cant handle datetime objects
  time_now = datetime.datetime.utcnow()
  mongo_event_object = { "author": author,
                         "message": message,
                         "email": email,
                         "channel": channel,
                         "gravatar": gravatar,
                         "datetime": time_now }
  # db insertion adds an _id field
  db.events.insert(mongo_event_object)
  msgpack_event_object = { "action":"message",
                           "data": message_dict_from_event_object(mongo_event_object),
                         }
  packed = g.msg_packer.pack(msgpack_event_object)

  # -> Everyone
  # prepend an identifier showing which channel the event happened on for PUB/SUB
  push_socket.send(" ".join([user_channels[channel], packed]))


# event_type must be either "join" or "leave"
def handle_self_channel_event(client_id, websocket, data, event_type):
  if client_id == data["client_id"]:
    return

  # force a refresh on all other clients
  # TODO(kle): live update the client's UI instead
  websocket.send(json.dumps({ "action": "force_refresh", "data": {} }))
