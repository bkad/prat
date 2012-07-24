from pymongo import DESCENDING
from flask import Blueprint, g, render_template, request, current_app
from random import shuffle
from chat.datastore import db, get_recent_messages, message_dict_from_event_object
import json

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  channels = g.user["channels"]
  message_dict = {}
  for channel in channels:
    messages = get_recent_messages(channel)
    message_dict[channel] = [message_dict_from_event_object(message) for message in messages]
  initial_messages = json.dumps(message_dict)
  last_selected_channel = g.user["last_selected_channel"]
  # maybe use backchat, flexjaxlot (it lines it up nicely)
  name_jumble = ["back", "flex", "jax", "chat", "lot"]
  shuffle(name_jumble)
  title = "".join(name_jumble)

  right_sidebar_closed = request.cookies.get("rightSidebar") == "closed"
  left_sidebar_closed = request.cookies.get("leftSidebar") == "closed"

  with current_app.open_resource("templates/message_container.mustache") as message_container_mustache:
    message_container_template = message_container_mustache.read()
  with current_app.open_resource("templates/message_partial.mustache") as message_partial_mustache:
    message_partial_template = message_partial_mustache.read()

  return render_template('index.htmljinja',
                         initial_messages=initial_messages,
                         authed=g.authed,
                         name_jumble=name_jumble,
                         title=title,
                         user_name=g.user['name'],
                         avatar_url=g.user["gravatar"],
                         channels=channels,
                         last_selected_channel=last_selected_channel,
                         right_sidebar_closed=right_sidebar_closed,
                         left_sidebar_closed=left_sidebar_closed,
                         time_window=current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"],
                         message_container_template=message_container_template,
                         message_partial_template=message_partial_template,
                        )
