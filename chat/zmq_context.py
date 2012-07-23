from flask import _app_ctx_stack, current_app
from gevent_zeromq import zmq
from werkzeug.local import LocalProxy

def init_app(app):
  app.teardown_appcontext(shutdown_zmq)

def _get_zmq_context():
  app_context = _app_ctx_stack.top
  return getattr(app_context, "oochat_zmq", None)

def get_or_create_zmq_context():
  if getattr(current_app, "oochat_zmq", None) is None:
    current_app.oochat_zmq = zmq.Context()
  return current_app.oochat_zmq
  # TODO(kle): figure out why zeromq contexts leak file descriptors when they're destroyed
  #context = _get_zmq_context()
  #app_context = _app_ctx_stack.top
  #if context is None:
  #  context = zmq.Context()
  #  app_context.oochat_zmq = context
  #return context

def shutdown_zmq(error):
  context = _get_zmq_context()
  if context is not None:
    context.destroy()

zmq_context = LocalProxy(get_or_create_zmq_context)
