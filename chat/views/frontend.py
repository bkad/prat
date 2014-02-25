# coding=utf-8

from flask import Blueprint, g, render_template, request, current_app, redirect, url_for
from chat.views.assets import asset_url
from chat.datastore import get_user_preferences, db, add_user_to_channel
from urlparse import urlparse
import codecs
from chat import markdown

frontend = Blueprint("frontend", __name__)

def read_template(template_name):
  with current_app.open_resource("templates/" + template_name) as template:
    return template.read().decode("utf-8")

vendor_js_files = [
  "jquery/dist/jquery.js",
  "angular/angular.js",
  "angular-animate/angular-animate.js",
  "angular-cookies/angular-cookies.js",
  "angular-sanitize/angular-sanitize.js",
  "angular-route/angular-route.js",
  "angular-bindonce/bindonce.js",
  "angular-ui-bootstrap-bower/ui-bootstrap-tpls.js",
  "angular-ui-router/release/angular-ui-router.js",
  "angular-ui-utils/ui-utils.js",
  "angular-ui-sortable/sortable.js",
  "jquery-ui/ui/jquery.ui.core.js",
  "jquery-ui/ui/jquery.ui.widget.js",
  "jquery-ui/ui/jquery.ui.mouse.js",
  "jquery-ui/ui/jquery.ui.sortable.js",
  #"jquery-caret/jquery.caret.js",
  #"jquery.scrollTo/jquery.scrollTo.js",
  #"prat-bootstrap/js/bootstrap-transition.js",
  #"prat-bootstrap/js/bootstrap-alert.js",
  #"prat-bootstrap/js/bootstrap-modal.js",
  #"prat-bootstrap/js/bootstrap-tooltip.js",
  "js-md5/js/md5.js",
  #"mustache/mustache.js",
  "underscore/underscore.js",
  "backbone/backbone.js",
  #"jquery.hotkeys/jquery.hotkeys.js",
  #"spin.js/spin.js",
]

#coffee_files = ["user_guide", "util", "message_hub", "chat", "chat_controls", "channel_controls",
    #"datetime", "sound", "alert", "user_statuses", "preferences", "imgur_uploader", "initialize"]
coffee_files = [
  "angular/app",
  "angular/services",
  "angular/services/event-hub",
  "angular/controllers/main",
]

sass_files = ["main"]

#mustache_files = ["message_container", "message_partial", "alert", "user_status", "channel_button", "info",
    #"boolean_preference"]
template_files = ["main"]

@frontend.route('')
def index():
  join_channel = request.args.get("channel")
  if join_channel:
    g.user["last_selected_channel"] = join_channel
    add_user_to_channel(g.user, join_channel)

  channels = g.user["channels"]

  last_selected_channel = g.user["last_selected_channel"]
  username = g.user["email"].split("@")[0]

  context = {
    "username": username,
    "email": g.user["email"],
    "channels": channels,
    "lastSelectedChannel": last_selected_channel,
    "preferences": get_user_preferences(g.user),
    "imgurClientId": current_app.config["IMGUR_CLIENT_ID"],
    "collapseTimeWindow": current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"],
    "name": current_app.config["APP_NAME"],
    "websocketKeepAliveInterval": current_app.config["WEBSOCKET_KEEP_ALIVE_INTERVAL"],
  }

  if current_app.config["REWRITE_MAIN_TEMPLATE"]:
    write_main_template()
  headers = {
    "Cache-Control": "no-store",
  }

  return (render_square_bracket_template("index.htmljinja", { "initial": context }), 200, headers)

def get_templates():
  #write_info_template()
  templates = []
  for template_name in template_files:
    template_content = read_template(template_name + ".html")
    templates.append((template_name + "-template", template_content))
  return templates

def write_main_template():
  template = render_template("index.pre.htmljinja",
      templates=get_templates(),
      coffee_files=coffee_files,
      sass_files=sass_files,
      asset_url=asset_url,
      vendor_js_files=vendor_js_files)
  with codecs.open("chat/templates/index.htmljinja", "w", encoding="utf-8") as template_file:
    template_file.write(template)

def render_square_bracket_template(template_name, context):
  env = current_app.jinja_env.overlay(block_start_string = "[%",
                                      block_end_string = "%]",
                                      variable_start_string = "[[",
                                      variable_end_string = "]]",
                                      comment_start_string = "[#",
                                      comment_end_string = "#]")
  current_app.update_template_context(context)
  template = env.get_template(template_name)
  return template.render(**context)

def write_info_template():
  args = { name: markdown.render(read_template(name + ".md"))
      for name in ["channel_info", "markdown_info", "faq"] }
  rendered = render_square_bracket_template("info.mustachejinja", args)
  with codecs.open("chat/templates/info.mustache", "w", encoding="utf-8") as template_file:
    template_file.write(rendered)
