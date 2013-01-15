from flask import Blueprint, request, g
import json
from chat.datastore import get_channel_users, get_recent_messages, get_messages_since_id

api = Blueprint("api", __name__)

@api.route("/user_status/<path:channel>")
def user_statuses_channel(channel):
  return json.dumps(get_channel_users(channel))

@api.route("/user_status")
def user_status():
  user_statuses = { channel: get_channel_users(channel) for channel in g.user["channels"] }
  return json.dumps(user_statuses)

@api.route("/messages/<path:channel>")
def messages(channel):
  return json.dumps(get_recent_messages(channel))

@api.route("/messages_since/<message_id>")
def messages_since_id(message_id):
  messages, errorString, errorCode = get_messages_since_id(message_id, g.user["channels"])
  if errorString is not None:
    return errorString, errorCode
  return json.dumps(messages)

@api.route("/whoami")
def whoami():
  user = {
    "email": g.user["email"],
    "name": g.user["name"],
    "gravatar": g.user["gravatar"],
    "channels": g.user["channels"],
    "username": g.user["email"].split("@")[0],
  }
  return json.dumps({ "user": user })
