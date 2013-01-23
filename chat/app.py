from . import views
from .config import DefaultConfig
from flask import Flask, g, jsonify, request, render_template, session, redirect, url_for
from flask.ext.openid import OpenID
from chat.datastore import db
from chat.crypto import check_request
import gevent.monkey
gevent.monkey.patch_all()

DEFAULT_APP = "chat"
DEFAULT_BLUEPRINTS = (
    (views.frontend, "/", "login_required"),
    (views.assets, "/assets", "login_required"),
    (views.eventhub, "/eventhub", "login_required"),
    (views.api, "/api", "login_required"),
    (views.auth, "/auth", None),
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
  oid.init_app(app)
  return app


def check_login():
  if getattr(g, "user", None) is None:
    return redirect(url_for("auth.login"))


def configure_blueprints(app, blueprints):
  for blueprint, url_prefix, login_required in blueprints:
    if login_required:
      blueprint.before_request(check_login)
    app.register_blueprint(blueprint, url_prefix=url_prefix)

def configure_before_handlers(app):
  @app.before_request
  def setup():
    g.authed = False

    # Catch logged in users
    if "email" in session:
      user = db.users.find_one({"email": session["email"]})
      if user is not None:
        g.user =  user
        g.authed = True
    elif("api_key" in request.args and
         "signature" in request.args and
         "expires" in request.args):
      user = db.users.find_one({"api_key": request.args["api_key"]})
      if user is None:
        return
      if check_request(request, user["secret"]):
        g.user = user
        g.authed = True
        session["email"] = user["email"]


def configure_error_handlers(app):
  @app.errorhandler(404)
  def page_not_found(error):
    if request.is_xhr:
      return jsonify(error="Resource not found")
    return render_template("404.htmljinja", error=error), 404
