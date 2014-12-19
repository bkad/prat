import gevent.monkey
gevent.monkey.patch_all()

from . import views
from .config import Config
from flask import Flask, g, jsonify, request, render_template, session, redirect, url_for
from prat.views.auth import oid
from prat.datastore import get_user
from prat.crypto import check_request
import urllib
from urlparse import urlparse
import logging
from logging.handlers import SMTPHandler
from logging import Formatter


DEFAULT_APP = "prat"
DEFAULT_BLUEPRINTS = (
    (views.frontend, "/", "login_required"),
    (views.assets, "/assets", "login_required"),
    (views.eventhub, "/eventhub", "login_required"),
    (views.api, "/api", "login_required"),
    (views.auth, "/auth", None),
)

def create_app(config=None, app_name=None, blueprints=None):
  if app_name is None:
    app_name = DEFAULT_APP
  if config is None:
    config = Config()

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
    if using_api_key_auth():
      return "Invalid signature", 400
    redirect_query_string = urllib.urlencode([("next", request.path),
                                              ("args", urlparse(request.url).query)])
    return redirect(url_for("auth.login") + "?" +  redirect_query_string)

def using_api_key_auth():
  return all(arg in request.args for arg in ["api_key", "signature", "expires"])

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
    if using_api_key_auth():
      user = get_user(api_key=request.args["api_key"])
      if user is None:
        return
      if check_request(request, user["secret"]):
        g.user = user
        g.authed = True
        session["email"] = user["email"]
    elif "email" in session:
      user = get_user(email=session["email"])
      if user is not None:
        g.user =  user
        g.authed = True

def configure_error_handlers(app):
  @app.errorhandler(404)
  def page_not_found(error):
    if request.is_xhr:
      return jsonify(error="Resource not found")
    return render_template("404.htmljinja", error=error), 404

  if app.debug:
    return

  mail_handler = SMTPHandler("127.0.0.1", app.config["ERROR_EMAIL"], app.config["ADMIN_EMAIL"], "Prat Error")
  mail_handler.setFormatter(Formatter("""
  Message type: %(levelname)s
  Location: %(pathname)s:%(lineno)d
  Module: %(module)s
  Function: %(funcName)s
  Time: %(asctime)s

  Message:

  %(message)s
  """))
  mail_handler.setLevel(logging.ERROR)
  app.logger.addHandler(mail_handler)
