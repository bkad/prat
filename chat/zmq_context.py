from flask import _app_ctx_stack
from gevent_zeromq import zmq
from werkzeug.local import LocalProxy

def init_app(app):
  app.teardown_appcontext(shutdown_zmq)

def _get_zmq_context():
  app_context = _app_ctx_stack.top
  return getattr(app_context, "oochat_zmq", None)

def get_or_create_zmq_context():
  context = _get_zmq_context()
  if context is None:
    context = zmq.Context()
  return context

def shutdown_zmq(error):
  context = _get_zmq_context()
  if context is not None:
    context.destroy()

zmq_context = LocalProxy(get_or_create_zmq_context)
