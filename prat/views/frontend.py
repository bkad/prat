# coding=utf-8

from flask import Blueprint, g, render_template, request, current_app, redirect, url_for
from prat.views.assets import asset_url
from prat.datastore import get_user_preferences, db, add_user_to_channel
from urlparse import urlparse
import codecs
from prat import markdown

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
  "angular-ui-bootstrap-bower/ui-bootstrap-tpls.js",
  "angular-ui-utils/ui-utils.js",
  "angular-ui-sortable/sortable.js",
  "jquery-ui/ui/jquery.ui.core.js",
  "jquery-ui/ui/jquery.ui.widget.js",
  "jquery-ui/ui/jquery.ui.mouse.js",
  "jquery-ui/ui/jquery.ui.sortable.js",
  "mustache/mustache.js",
  "underscore/underscore.js",
  "backbone/backbone.js",
]

coffee_files = ["scripts/" + f for f in [
  "app",
  "directives/messages",
  "directives/check-scrolled-to-bottom",
  "services/event-hub",
  "services/human-date",
  "services/scrolled-to-bottom",
  "controllers/main",
  "controllers/info",
]]

sass_files = ["all"]

template_files = [
  ("main", "html"),
  ("info", "html"),
]

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
  }

  if current_app.config["REWRITE_MAIN_TEMPLATE"]:
    write_main_template()
  headers = {
    "Cache-Control": "no-store",
  }

  return (render_square_bracket_template("index.htmljinja", {"initial": context}), 200, headers)

def get_templates():
  write_info_template()
  templates = []
  for template_name, extension in template_files:
    template_content = read_template("{name}.{ext}".format(name=template_name, ext=extension))
    templates.append((template_name + "-template", template_content))
  return templates

def write_main_template():
  template = render_template("index.pre.htmljinja",
      templates=get_templates(),
      coffee_files=coffee_files,
      sass_files=sass_files,
      asset_url=asset_url,
      vendor_js_files=vendor_js_files)
  with codecs.open("prat/templates/index.htmljinja", "w", encoding="utf-8") as template_file:
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
  args = { name: markdown.render(read_template("{}.md".format(name)))
      for name in ["channel_info", "markdown_info", "faq"] }
  rendered = render_square_bracket_template("info.htmljinja", args)
  with codecs.open("prat/templates/info.html", "w", encoding="utf-8") as template_file:
    template_file.write(rendered)
