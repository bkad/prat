import pymongo
from chat import markdown
from chat.tardis import datetime_to_unix
from pymongo import DESCENDING, ASCENDING, MongoClient
from flask import current_app
from werkzeug.local import LocalProxy
from bson.objectid import ObjectId, InvalidId
from redis import StrictRedis
import base64

def get_db():
  connection = getattr(current_app, "oochat_db", None)
  if connection is None:
    connection = current_app.oochat_db = MongoClient(host=current_app.config["MONGO_HOST"],
                                                     port=current_app.config["MONGO_PORT"],
                                                     tz_aware=True)
  return getattr(connection, current_app.config["MONGO_DB_NAME"])

def get_redis_connection():
  connection = getattr(current_app, "oochat_redis", None)
  if connection is None:
    connection = current_app.oochat_redis = StrictRedis(host=current_app.config["REDIS_HOST"],
                                                        port=current_app.config["REDIS_PORT"])
  return connection

def get_recent_messages(channel):
  ascending = reversed(list(db.events.find({"channel":channel}).sort("$natural", DESCENDING).limit(100)))
  return [message_dict_from_event_object(message) for message in ascending]

def get_messages_since_id(message_id, channels):
  # TODO(kle): limit the max number of messages fetched
  find_args = { "channel": { "$in": channels } }
  if message_id is not "none":
    try:
      find_args["_id"] = { "$gt": ObjectId(message_id) }
    except InvalidId:
      return [], "Invalid message id", 400
  events = db.events.find(find_args).sort("$natural", ASCENDING)
  return [message_dict_from_event_object(event) for event in events], None, 200

def message_dict_from_event_object(event_object):
  message = event_object["message"] or " "
  return { "message_id": str(event_object["_id"]),
           "channel": event_object["channel"],
           "datetime": datetime_to_unix(event_object["datetime"]),
           "rendered_message": markdown.render(message),
           "message": message,
           "user": {
             "name": event_object["author"],
             "gravatar": event_object["gravatar"],
             "username": event_object["email"].split("@")[0],
             "email": event_object["email"],
           },
         }

def get_channel_users(channel):
  user_statuses = redis_db.hgetall(redis_channel_key(channel))
  user_list = []
  for email, status in user_statuses.iteritems():
    mongo_user = db.users.find_one({ "email": email })
    if mongo_user is None:
      mongo_user = {
        "name": "Not Found",
        "gravatar": "static/anon.jpg",
      }

    user_list.append({
      "email": email,
      "status": status,
      "name": mongo_user["name"],
      "gravatar": mongo_user["gravatar"],
      "username": email.split("@")[0],
    })

  return user_list

# Helper function to translate channel name into a prefix for zmq messages (for pubsub)
def zmq_channel_key(channel_name):
  return base64.b64encode(channel_name.encode("utf-8"))

def redis_channel_key(channel_name):
  return "channel:" + channel_name

def add_user_to_channel(user, channel_name):
  if channel_name not in user["channels"]:
    user["channels"].append(channel_name)
    db.users.save(user)

  set_user_channel_status(user, channel_name, "active")

  return zmq_channel_key(channel_name)

def remove_user_from_channel(user, channel_name):
  if channel_name in user["channels"]:
    user["channels"].remove(channel_name)
    db.users.save(user)

  channel_key = redis_channel_key(channel_name)
  redis_db.hdel(channel_key, user["email"])

  return zmq_channel_key(channel_name)

def reorder_user_channels(user, channels):
  user["channels"] = channels
  db.users.save(user)

def get_user_channel_status(user, channel_name):
  channel_key = redis_channel_key(channel_name)
  return redis_db.hget(channel_key, user["email"])

def set_user_channel_status(user, channel_name, status):
  channel_key = redis_channel_key(channel_name)
  redis_db.hset(channel_key, user["email"], status)

def user_clients_key(user):
  return "user-client:" + user["email"] + ":"

def add_to_user_clients(user, client_id):
  redis_key = user_clients_key(user) + client_id
  timeout = current_app.config["REDIS_USER_CLIENT_TIMEOUT"]
  redis_db.pipeline().set(redis_key, 1).expire(redis_key, timeout).execute()

def remove_from_user_clients(user, client_id):
  redis_key = user_clients_key(user) + client_id
  redis_db.delete(redis_key)

def refresh_user_client(user, client_id):
  redis_key = user_clients_key(user) + client_id
  timeout = current_app.config["REDIS_USER_CLIENT_TIMEOUT"]
  result = redis_db.expire(redis_key, timeout)
  if result == 0:
    add_to_user_clients(user, client_id)
  return result

def get_active_clients_count(user):
  prefix = user_clients_key(user) + "*"
  return len(redis_db.keys(prefix))

def get_user_preferences(user):
  preferences = user.get("preferences")
  if preferences is None:
    preferences = {}
  return preferences

def update_user_preferences(user, new_preferences):
  preferences = get_user_preferences(user)
  preferences.update(new_preferences)
  user["preferences"] = preferences
  db.users.save(user)
  return preferences

db = LocalProxy(get_db)
redis_db = LocalProxy(get_redis_connection)
