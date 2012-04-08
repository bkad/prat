from . import views
from .config import DefaultConfig
from flask import Flask, g, jsonify, request, render_template
import pymongo
import gevent.monkey
gevent.monkey.patch_all()

DEFAULT_APP = "chat"
DEFAULT_BLUEPRINTS = (
    (views.frontend, ""),
    (views.assets, "/assets"),
    (views.eventhub, "/eventhub"),
)

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
  return app

def configure_blueprints(app, blueprints):
  for blueprint, url_prefix in blueprints:
    app.register_blueprint(blueprint, url_prefix=url_prefix)

def configure_before_handlers(app):
  @app.before_request
  def setup_mongo():
    g.mongo = pymongo.Connection(host=app.config["MONGO_HOST"], port=app.config["MONGO_PORT"], tz_aware=True)
    g.events = g.mongo.oochat.events

def configure_error_handlers(app):
  @app.errorhandler(404)
  def page_not_found(error):
    if request.is_xhr:
      return jsonify(error="Resource not found")
    return render_template("404.htmljinja", error=error), 404
