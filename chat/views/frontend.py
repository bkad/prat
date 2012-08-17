# coding=utf-8

from pymongo import DESCENDING
from flask import Blueprint, g, render_template, request, current_app
from random import shuffle
from chat.datastore import db, get_recent_messages, message_dict_from_event_object, get_channel_users

frontend = Blueprint("frontend", __name__)

def read_template(template_name):
  with current_app.open_resource("templates/" + template_name) as template:
    return template.read().decode("utf-8")

@frontend.route('/')
def index():
  channels = g.user["channels"]

  initial_messages = {}
  initial_users = {}
  for channel in channels:
    messages = get_recent_messages(channel)
    initial_messages[channel] = [message_dict_from_event_object(message) for message in messages]
    initial_users[channel] = get_channel_users(channel)

  last_selected_channel = g.user["last_selected_channel"]
  username = g.user["email"].split("@")[0]

  right_sidebar_closed = request.cookies.get("rightSidebar") == "closed"
  left_sidebar_closed = request.cookies.get("leftSidebar") == "closed"

  message_container_template = read_template("message_container.mustache")
  message_partial_template = read_template("message_partial.mustache")
  alert_template = read_template("alert.mustache")
  user_status_template = read_template("user_status.mustache")
  channel_button_template = read_template("channel_button.mustache")

  return render_template("index.htmljinja",
                         initial_messages=initial_messages,
                         initial_users=initial_users,
                         authed=g.authed,
                         full_name=g.user["name"],
                         username=username,
                         email=g.user["email"],
                         avatar_url=g.user["gravatar"],
                         channels=channels,
                         last_selected_channel=last_selected_channel,
                         right_sidebar_closed=right_sidebar_closed,
                         left_sidebar_closed=left_sidebar_closed,
                         time_window=current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"],
                         message_container_template=message_container_template,
                         message_partial_template=message_partial_template,
                         alert_template=alert_template,
                         user_status_template=user_status_template,
                         channel_button_template=channel_button_template,
                         title=current_app.config["APP_NAME"],
                         debug=current_app.config["DEBUG"],
                        )
