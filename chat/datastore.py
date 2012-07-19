import pymongo
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

db = LocalProxy(get_db)
