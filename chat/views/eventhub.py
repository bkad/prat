from flask import Blueprint, request, g, current_app, render_template
import datetime
import geventwebsocket
from gevent_zeromq import zmq
import json
from chat.datastore import (db, message_dict_from_event_object, remove_user_from_channel,
                            add_user_to_channel, zmq_channel_key, set_user_channel_status,
                            add_to_user_clients, remove_from_user_clients, get_active_clients_count)
from chat.zmq_context import zmq_context
from chat import markdown
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
  client_id = uuid.uuid4()

  subscribe_socket.connect(current_app.config["SUBSCRIBE_ADDRESS"])

  # add yourself to your current pool of open clients
  add_to_user_clients(g.user, client_id)

  # listen for messages that happen on channels the user is subscribed to
  for channel in g.user["channels"]:
    channel_id = zmq_channel_key(channel)
    subscribe_socket.setsockopt(zmq.SUBSCRIBE, channel_id)
    set_user_channel_status(g.user, channel, "active")
    send_user_status_update(g.user, channel, push_socket, "active")

  # subscribe to events the user triggered that could affect the user's other open clients
  subscribe_socket.setsockopt_string(zmq.SUBSCRIBE, g.user["email"])

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
        if action in ["publish_message", "join_channel", "leave_channel", "user_active", "user_offline"]:
          websocket.send(json.dumps(unpacked))
        elif action in ["self_join_channel", "self_leave_channel"]:
          event_type = action.split("_")[1]
          handle_self_channel_event(client_id, websocket, subscribe_socket, unpacked["data"], event_type)

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
          handle_publish_message(data, push_socket)
        elif action == "preview_message":
          handle_preview_message(data, websocket)
        elif action == "join_channel":
          handle_join_channel(data["channel"], subscribe_socket, push_socket, client_id)
        elif action == "leave_channel":
          handle_leave_channel(data["channel"], subscribe_socket, push_socket, client_id)
  except geventwebsocket.WebSocketError, e:
    print "{0} {1}".format(e.__class__.__name__, e)

  remove_from_user_clients(g.user, client_id)
  if get_active_clients_count(g.user) == 0:
    for channel in g.user["channels"]:
      set_user_channel_status(g.user, channel, "offline")
      send_user_status_update(g.user, channel, push_socket, "offline")

  # TODO(kle): figure out how to clean up websockets left in a CLOSE_WAIT state
  push_socket.close()
  subscribe_socket.close()
  websocket.close()
  return ""


def handle_leave_channel(channel, subscribe_socket, push_socket, client_id):
  # unsubscribe to events happening on this channel
  subscribe_socket.setsockopt(zmq.UNSUBSCRIBE, channel_id)

  channel_id = remove_user_from_channel(g.user, channel)

  leave_channel_event = {
      "action": "leave_channel",
      "data": {
        "email": g.user["email"],
        "channel": channel,
      },
  }
  # alert channel subscribers to user leaving
  packed_leave_channel = g.msg_packer.pack(leave_channel_event)
  push_socket.send(" ".join(channel_id, packed_leave_channel))

  self_leave_channel_event = {
      "action": "self_leave_channel",
      "data": {
        "client_id": client_id,
        "channel": channel,
        "channel_id": channel_id,
      },
  }
  packed_self_leave_channel = g.msg_packer.pack(self_leave_channel_event)
  push_socket.send(" ".join(g.user["email"], packed_self_leave_channel))


def send_join_channel(channel, user, push_socket):
  channel_id = zmq_channel_key(channel)
  join_channel_event = {
      "action": "join_channel",
      "data": {
        "channel": channel,
        "user": {
          "email": user["email"],
          "gravatar": user["gravatar"],
          "name": user["name"],
          "username": user["email"].split("@")[0],
          "status": "active",
        },
      },
  }
  # alert channel subscribers to new user
  packed_join_channel = g.msg_packer.pack(join_channel_event)
  push_socket.send(" ".join([channel_id, packed_join_channel]))


def handle_join_channel(channel, subscribe_socket, push_socket, client_id):
  channel_id = add_user_to_channel(g.user, channel)

  send_join_channel(channel, g.user, push_socket)

  # subscribe to events happening on this channel
  subscribe_socket.setsockopt(zmq.SUBSCRIBE, channel_id)

  join_channel_event = {
      "action": "join_channel",
      "data": {
        "channel": channel,
        "user": {
          "email": g.user["email"],
          "gravatar": g.user["gravatar"],
          "name": g.user["name"],
          "username": g.user["email"].split("@")[0],
          "status": "active",
        },
      },
  }
  # alert channel subscribers to new user
  packed_join_channel = g.msg_packer.pack(join_channel_event)
  push_socket.send(" ".join([channel_id, packed_join_channel]))

  # alert the user's other open clients of the change
  self_join_channel_event = {
      "action": "self_join_channel",
      "data": {
        "client_id": client_id,
        "channel": channel,
        "channel_id": channel_id,
      },
  }
  packed_self_join_channel = g.msg_packer.pack(self_join_channel_event)
  push_socket.send(" ".join([g.user["email"], packed_self_join_channel]))

def send_user_status_update(user, channel, push_socket, status):
  event_object = {
      "action": "user_" + status,
      "data": {
        "email": user["email"],
      },
  }
  packed = g.msg_packer.pack(event_object)
  push_socket.send(" ".join([zmq_channel_key(channel), packed]))


def handle_switch_channel(channel):
  # Update channel logged in user is subscribed to
  g.user["last_selected_channel"] = channel
  db.users.save(g.user)


def handle_publish_message(data, push_socket):
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
  msgpack_event_object = { "action":"publish_message",
                           "data": message_dict_from_event_object(mongo_event_object),
                         }
  packed = g.msg_packer.pack(msgpack_event_object)

  # -> Everyone
  # prepend an identifier showing which channel the event happened on for PUB/SUB
  push_socket.send(" ".join([zmq_channel_key(channel), packed]))

def handle_preview_message(data, websocket):
  message = data["message"]
  channel = data["channel"]
  author = g.user["name"]
  email = g.user["email"]
  gravatar = g.user["gravatar"]
  # we use isoformat in msgpack because it cant handle datetime objects
  time_now = datetime.datetime.utcnow()
  preview_event_object = { "message_id": "0000",
                           "message": message,
                           "rendered_message": markdown.render(message)
                         }

  msgpack_event_object = { "action":"preview_message",
                           "data": preview_event_object,
                         }
  #packed = g.msg_packer.pack(msgpack_event_object)

  # -> Self
  websocket.send(json.dumps(msgpack_event_object))


# event_type must be either "join" or "leave"
def handle_self_channel_event(client_id, websocket, subscribe_socket, data, event_type):
  # if the client that triggered the update is yourself, then ignore it
  if client_id == data["client_id"]:
    return

  channel_id = data["channel_id"]
  channel = data["channel"]
  if event_type == "join":
    subscribe_socket.setsockopt(zmq.SUBSCRIBE, channel_id)
    if channel not in g.user["channels"]:
      g.user["channels"].append(channel)
  elif event_type == "leave":
    subscribe_socket.setsockopt(zmq.UNSUBSCRIBE, channel_id)
    if channel in g.user["channels"]:
      g.user["channels"].remove(channel)

  # force a refresh on all other clients
  # TODO(kle): live update the client's UI instead
  websocket.send(json.dumps({ "action": "force_refresh", "data": {} }))
