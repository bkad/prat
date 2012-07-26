import pymongo
from chat import markdown
from chat.tardis import datetime_to_unix
from pymongo import DESCENDING
from flask import _app_ctx_stack
from werkzeug.local import LocalProxy

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

db = LocalProxy(get_db)
