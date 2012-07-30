from . import views
from .config import DefaultConfig
from flask import Flask, g, jsonify, request, render_template, session
from flaskext.openid import OpenID
from random import randint
from gevent_zeromq import zmq
import zmq_context
import msgpack
import datastore
from chat.datastore import db
import gevent.monkey
gevent.monkey.patch_all()

DEFAULT_APP = "chat"
DEFAULT_BLUEPRINTS = (
    (views.frontend, "/"),
    (views.assets, "/assets"),
    (views.eventhub, "/eventhub"),
    (views.auth, None),
)

oid = OpenID()

def create_app(config=None, app_name=None, blueprints=None):
  if app_name is None:
    app_name = DEFAULT_APP
  if config is None:
    config = DefaultConfig()
  if blueprints is None:
    blueprints = DEFAULT_BLUEPRINTS

  app = Flask(app_name)
  app.config.from_object(config)

  datastore.init_app(app)
  zmq_context.init_app(app)

  configure_blueprints(app, blueprints)
  configure_before_handlers(app)
  configure_error_handlers(app)
  oid.init_app(app)
  return app

def configure_blueprints(app, blueprints):
  for blueprint, url_prefix in blueprints:
    app.register_blueprint(blueprint, url_prefix=url_prefix)

def configure_before_handlers(app):
  @app.before_request
  def setup():
    g.msg_packer = msgpack.Packer()
    g.msg_unpacker = msgpack.Unpacker()

    g.authed = False

    # Create anonymous handle for unauthed users
    if 'anon_uname' not in session:
      session['anon_uname'] = "Anon{0}".format(randint(1000,9999))
    g.user = { "name": unicode(session['anon_uname']),
               "gravatar": "static/anon.jpg",
               "email": unicode(session["anon_uname"]),
               "channels": ["general"],
               "last_selected_channel": "general" }

    # Catch logged in users
    if "email" in session:
      user = db.users.find_one({"email" : session["email"]})
      if user is not None:
        g.user =  user
        g.authed = True

def configure_error_handlers(app):
  @app.errorhandler(404)
  def page_not_found(error):
    if request.is_xhr:
      return jsonify(error="Resource not found")
    return render_template("404.htmljinja", error=error), 404
