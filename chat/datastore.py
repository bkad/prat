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
  return reversed(list(db.events.find({"channel":channel}).sort("$natural", DESCENDING).limit(100)))

def message_dict_from_event_object(event_object):
  return { "message_id": str(event_object["_id"]),
           "author": event_object["author"],
           "channel": event_object["channel"],
           "gravatar": event_object["gravatar"],
           "username": event_object["email"].split("@")[0],
           "datetime": datetime_to_unix(event_object["datetime"]),
           "email": event_object["email"],
           "message": markdown.render(event_object["message"] or " "),
         }


# Helper function to translate channel name into a prefix for zmq messages (for pubsub)
def zmq_channel_key(channel_name):
  return base64.b64encode(channel_name)

def redis_channel_key(channel_name):
  return "channel-" + channel_name

def add_user_to_channel(user, channel_name):
  if channel_name not in user["channels"]:
    user["channels"].append(channel_name)
    db.users.save(user)

  channel_key = redis_channel_key(channel_name)
  redis_db.hsetnx(channel_key, user["email"], "active")

  return zmq_channel_key(channel_name)

def remove_user_from_channel(user, channel_name):
  if channel_name in user["channels"]:
    user["channels"].remove(channel_name)
    db.users.save(user)

  channel_key = redis_channel_key(channel_name)
  redis_db.hdel(channel_key, user["email"])

  return zmq_channel_key(channel_name)

def set_user_active(user, channel_name):
  channel_key = redis_channel_key(channel_name)
  redis_db.hset(channel_key, user["email"], "active")

db = LocalProxy(get_db)
redis_db = LocalProxy(get_redis_connection)
