from flask import Blueprint, request, g
import json
from bson import InvalidDocument
from chat.datastore import (get_channel_users, get_recent_messages, get_messages_since_id,
    get_user_preferences, update_user_preferences)
from chat import markdown

api = Blueprint("api", __name__)

@api.route("/user_status/<path:channel>")
def user_statuses_channel(channel):
  return json.dumps(get_channel_users(channel))

@api.route("/user_status")
def user_status():
  user_statuses = { channel: get_channel_users(channel) for channel in g.user["channels"] }
  return json.dumps(user_statuses)

@api.route("/messages/<path:channel>")
def channel_messages(channel):
  return json.dumps(get_recent_messages(channel))

@api.route("/messages")
def messages():
  messages = { channel: get_recent_messages(channel) for channel in g.user["channels"] }
  return json.dumps(messages)

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

@api.route("/markdown", methods=["POST"])
def misaka():
  return markdown.render(request.data)

@api.route("/user/preferences", methods=["PATCH", "GET"])
def user_preferences():
  if request.method == "PATCH":
    try:
      new_preferences = json.loads(request.data)
    except ValueError:
      return "Could not parse JSON", 400
    try:
      return json.dumps(update_user_preferences(g.user, new_preferences))
    except InvalidDocument as e:
      return 400, "Invalid Document: {0}".format(e.message)
  elif request.method == "GET":
    return json.dumps(get_user_preferences(g.user))

