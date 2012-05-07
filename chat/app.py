from . import views
from .config import DefaultConfig
from flask import Flask, g, jsonify, request, render_template, session
from flaskext.openid import OpenID
from random import randint
import pymongo
from gevent_zeromq import zmq
import msgpack
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

  configure_blueprints(app, blueprints)
  configure_before_handlers(app)
  configure_error_handlers(app)
  configure_zmq(app)
  oid.init_app(app)
  return app

# dont create a context for each request
# it creates a bunch of lingering fd's that are hard to clean up
def configure_zmq(app):
  app.zmq_context = zmq.Context()

def configure_blueprints(app, blueprints):
  for blueprint, url_prefix in blueprints:
    app.register_blueprint(blueprint, url_prefix=url_prefix)

def configure_before_handlers(app):
  @app.before_request
  def setup():
    g.mongo = pymongo.Connection(host=app.config["MONGO_HOST"], port=app.config["MONGO_PORT"], tz_aware=True)
    g.events = g.mongo.oochat.events
    g.users = g.mongo.oochat.users

    g.msg_packer = msgpack.Packer()
    g.msg_unpacker = msgpack.Unpacker()

    g.authed = False

    # Create anonymous handle for unauthed users
    if 'anon_uname' in session:
      g.user = {"name": session['anon_uname']}
    else:
      session['anon_uname'] = "Anon{0}".format(randint(1000,9999))
      g.user = {"name": session['anon_uname']}

    # Catch logged in users
    if 'openid' in session:
      g.user = g.users.find_one({"openid" : session['openid']})
      g.authed = True

def configure_error_handlers(app):
  @app.errorhandler(404)
  def page_not_found(error):
    if request.is_xhr:
      return jsonify(error="Resource not found")
    return render_template("404.htmljinja", error=error), 404
