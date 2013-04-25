# coding=utf-8

from flask import Blueprint, g, render_template, request, current_app, redirect, url_for
from chat.views.assets import asset_url
from chat.datastore import get_user_preferences, db, add_user_to_channel
from urlparse import urlparse

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
  "mustache.js",
  "underscore-1.3.3-min.js",
  "backbone-0.9.2-min.js",
  "jquery.tipsy.js",
  "jquery.hotkeys.js",
  "spin.min.js",
]

coffee_files = ["user_guide", "util", "message_hub", "chat", "chat_controls", "channel_controls",
    "datetime", "sound", "alert", "user_statuses", "preferences"]

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

  mustache_templates = []
  for template in ["message_container", "message_partial", "alert", "user_status", "channel_button", "info",
      "preferences"]:
    template_id = template.replace("_", "-") + "-template"
    template_content = read_template(template + ".mustache")
    mustache_templates.append((template_id, template_content))

  stylus_files = ["style", "pygments", "tipsy_styles"]

  return render_template("index.htmljinja",
                         username=username,
                         email=g.user["email"],
                         channels=channels,
                         last_selected_channel=last_selected_channel,
                         right_sidebar_closed=right_sidebar_closed,
                         left_sidebar_closed=left_sidebar_closed,
                         mustache_templates=mustache_templates,
                         coffee_files=coffee_files,
                         stylus_files=stylus_files,
                         asset_url=asset_url,
                         vendor_js_files=vendor_js_files,
                         preferences=get_user_preferences(g.user),
                        )
