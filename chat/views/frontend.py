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
  "jquery-2.0.0.min.js",
  "jquery-ui-1.10.2.min.js",
  "jquery.caret.js",
  "jquery.scrollTo.min.js",
  "bootstrap-transition.js",
  "bootstrap-alert.js",
  "bootstrap-modal.js",
  "bootstrap-tooltip.js",
  "mustache.js",
  "underscore-1.3.3-min.js",
  "backbone-0.9.2-min.js",
  "jquery.hotkeys.js",
  "spin.min.js",
]

coffee_files = ["user_guide", "util", "message_hub", "chat", "chat_controls", "channel_controls",
    "datetime", "sound", "alert", "user_statuses", "preferences", "imgur_uploader"]

stylus_files = ["style", "pygments", "tooltip"]

@frontend.route('')
def index():
  join_channel = request.args.get("channel")
  if join_channel:
    g.user["last_selected_channel"] = join_channel
    add_user_to_channel(g.user, join_channel)

  channels = g.user["channels"]

  last_selected_channel = g.user["last_selected_channel"]
  username = g.user["email"].split("@")[0]

  right_sidebar_closed = (request.args.get("rightSidebar") or request.cookies.get("rightSidebar")) == "closed"
  left_sidebar_closed = (request.args.get("leftSidebar") or request.cookies.get("leftSidebar")) == "closed"

  context = {
    "username": username,
    "email": g.user["email"],
    "channels": channels,
    "last_selected_channel": last_selected_channel,
    "right_sidebar_closed": right_sidebar_closed,
    "left_sidebar_closed": left_sidebar_closed,
    "preferences": get_user_preferences(g.user),
  }

  if current_app.config["REWRITE_MAIN_TEMPLATE"]:
    write_main_template()

  return render_square_bracket_template("index.htmljinja", context)

def get_mustache_templates():
  write_info_template()
  mustache_templates = []
  for template in ["message_container", "message_partial", "alert", "user_status", "channel_button", "info"]:
    template_id = template.replace("_", "-") + "-template"
    template_content = read_template(template + ".mustache")
    mustache_templates.append((template_id, template_content))
  return mustache_templates

def write_main_template():
  template = render_template("index.pre.htmljinja",
      mustache_templates=get_mustache_templates(),
      coffee_files=coffee_files,
      stylus_files=stylus_files,
      asset_url=asset_url,
      vendor_js_files=vendor_js_files,
      preferences_snippet=read_template("preferences.html"))
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
