from flask import _app_ctx_stack, current_app
import zmq.green as zmq
from werkzeug.local import LocalProxy

def get_or_create_zmq_context():
  if getattr(current_app, "oochat_zmq", None) is None:
    current_app.oochat_zmq = zmq.Context()
  return current_app.oochat_zmq

def get_or_create_zmq_push_socket():
  if getattr(current_app, "oochat_zmq_push_socket", None) is None:
    current_app.oochat_zmq_push_socket = zmq_context.socket(zmq.PUSH)
    current_app.oochat_zmq_push_socket.connect(current_app.config["PUSH_ADDRESS"])
  return current_app.oochat_zmq_push_socket

zmq_context = LocalProxy(get_or_create_zmq_context)
push_socket = LocalProxy(get_or_create_zmq_push_socket)
