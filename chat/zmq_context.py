from flask import _app_ctx_stack, current_app
import zmq.green as zmq
from werkzeug.local import LocalProxy

def app_name():
  return current_app.config["APP_NAME"]

def get_or_create_zmq_context():
  ctx = getattr(current_app, app_name() + "_zmq", None)
  if ctx is None:
    ctx = zmq.Context()
    setattr(current_app, app_name() + "_zmq", ctx)
  return ctx

def get_or_create_zmq_push_socket():
  socket = getattr(current_app, app_name() + "_zmq_push_socket", None)
  if socket is None:
    socket = zmq_context.socket(zmq.PUSH)
    socket.connect(current_app.config["PUSH_ADDRESS"])
    setattr(current_app, app_name() + "_zmq_push_socket", socket)
  return socket

zmq_context = LocalProxy(get_or_create_zmq_context)
push_socket = LocalProxy(get_or_create_zmq_push_socket)
