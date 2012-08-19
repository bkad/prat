from flask import Blueprint, request
import json
from chat.datastore import get_channel_users, get_recent_messages

api = Blueprint("api", __name__)

@api.route("/user_status/<path:channel>")
def user_status(channel):
  return json.dumps(get_channel_users(channel))

@api.route("/messages/<path:channel>")
def messages(channel):
  return json.dumps(get_recent_messages(channel))
