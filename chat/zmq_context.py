from flask import _app_ctx_stack, current_app
import zmq.green as zmq
from werkzeug.local import LocalProxy

def get_or_create_zmq_context():
  if getattr(current_app, "oochat_zmq", None) is None:
    current_app.oochat_zmq = zmq.Context()
  return current_app.oochat_zmq

zmq_context = LocalProxy(get_or_create_zmq_context)
