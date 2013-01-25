# coding=utf-8

from flask import Blueprint, g, render_template, request, current_app
from chat.views.assets import asset_url

frontend = Blueprint("frontend", __name__)

def read_template(template_name):
  with current_app.open_resource("templates/" + template_name) as template:
    return template.read().decode("utf-8")

vendor_js_files = [
  "jquery-1.8.2.min.js",
  "jquery-ui-1.8.23.min.js",
  "jquery.hotkeys.js",
  "jquery.caret.js",
  "bootstrap-transition.js",
  "bootstrap-alert.js",
  "bootstrap-modal.js",
  "mustache.js",
  "underscore-1.3.3-min.js",
  "backbone-0.9.2-min.js",
  "jquery.tipsy.js",
  "spin.min.js",
]

@frontend.route('/')
def index():
  channels = g.user["channels"]

  last_selected_channel = g.user["last_selected_channel"]
  username = g.user["email"].split("@")[0]

  right_sidebar_closed = request.cookies.get("rightSidebar") == "closed"
  left_sidebar_closed = request.cookies.get("leftSidebar") == "closed"

  mustache_templates = []
  for template in ["message_container", "message_partial", "alert", "user_status", "channel_button"]:
    template_id = template.replace("_", "-") + "-template"
    template_content = read_template(template + ".mustache")
    mustache_templates.append((template_id, template_content))

  coffee_files = ["util", "message_hub", "chat", "chat_controls", "channel_controls", "datetime", "sound",
      "alert", "user_statuses"]

  stylus_files = ["style", "pygments", "tipsy_styles"]

  return render_template("index.htmljinja",
                         username=username,
                         email=g.user["email"],
                         channels=channels,
                         last_selected_channel=last_selected_channel,
                         right_sidebar_closed=right_sidebar_closed,
                         left_sidebar_closed=left_sidebar_closed,
                         time_window=current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"],
                         mustache_templates=mustache_templates,
                         title=current_app.config["APP_NAME"],
                         debug=current_app.config["DEBUG"],
                         keep_alive_interval=current_app.config["WEBSOCKET_KEEP_ALIVE_INTERVAL"],
                         coffee_files=coffee_files,
                         stylus_files=stylus_files,
                         asset_url=asset_url,
                         vendor_js_files=vendor_js_files,
                         compiled_js=current_app.config["COMPILED_JS"],
                         compiled_css=current_app.config["COMPILED_CSS"],
                         compiled_vendor_js=current_app.config["COMPILED_VENDOR_JS"],
                        )
