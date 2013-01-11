import pymongo
from chat import markdown
from chat.tardis import datetime_to_unix
from pymongo import DESCENDING
from flask import _app_ctx_stack
from werkzeug.local import LocalProxy
import redis
import base64

def init_app(app):
  app.teardown_appcontext(close_db_connection)

def _get_connection_attribute():
  context = _app_ctx_stack.top
  return getattr(context, "oochat_db", None)

def get_db_connection():
  context = _app_ctx_stack.top
  connection = _get_connection_attribute()
  if connection is None:
    connection = pymongo.Connection(host=context.app.config["MONGO_HOST"],
                                    port=context.app.config["MONGO_PORT"],
                                    tz_aware=True)
    context.oochat_db = connection
  return connection

def close_db_connection(error):
  connection = _get_connection_attribute()
  if connection is not None:
    connection.close()

def get_db():
  return get_db_connection().oochat

def get_redis_connection():
  context = _app_ctx_stack.top
  connection = getattr(context, "oochat_redis", None)
  if connection is None:
    connection = redis.StrictRedis(host=context.app.config["REDIS_HOST"],
                                   port=context.app.config["REDIS_PORT"])
    context.oochat_redis = connection
  return connection

def get_recent_messages(channel):
  ascending = reversed(list(db.events.find({"channel":channel}).sort("$natural", DESCENDING).limit(100)))
  return [message_dict_from_event_object(message) for message in ascending]

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
  redis_db.hget(channel_key, user["email"])

def set_user_channel_status(user, channel_name, status):
  channel_key = redis_channel_key(channel_name)
  redis_db.hset(channel_key, user["email"], status)

def user_clients_key(user):
  return "user-client:" + user["email"] + ":"

def add_to_user_clients(user, client_id):
  context = _app_ctx_stack.top
  redis_key = user_clients_key(user) + client_id
  timeout = context.app.config["REDIS_USER_CLIENT_TIMEOUT"]
  redis_db.pipeline().set(redis_key, 1).expire(redis_key, timeout).execute()

def remove_from_user_clients(user, client_id):
  redis_key = user_clients_key(user) + client_id
  redis_db.delete(redis_key)

def refresh_user_client(user, client_id):
  redis_key = user_clients_key(user) + client_id
  context = _app_ctx_stack.top
  timeout = context.app.config["REDIS_USER_CLIENT_TIMEOUT"]
  result = redis_db.expire(redis_key, timeout)
  if result == 0:
    add_to_user_clients(user, client_id)
  return result

def get_active_clients_count(user):
  prefix = user_clients_key(user) + "*"
  return len(redis_db.keys(prefix))


db = LocalProxy(get_db)
redis_db = LocalProxy(get_redis_connection)
