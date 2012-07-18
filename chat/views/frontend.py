from pymongo import DESCENDING
from flask import Blueprint, g, render_template, request, current_app
from chat.tardis import datetime_to_unix
from random import shuffle
from chat.markdown import markdown_renderer
from collections import OrderedDict
from chat.datastore import db, get_recent_messages

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  channels = g.user["channels"]
  message_dict = OrderedDict()
  for channel in channels:
    messages = get_recent_messages(channel)
    message_dict[channel] = collapsed_messages(messages)
  last_selected_channel = g.user["last_selected_channel"]
  # maybe use backchat, flexjaxlot (it lines it up nicely)
  name_jumble = ["back", "flex", "jax", "chat", "lot"]
  shuffle(name_jumble)
  title = "".join(name_jumble)
  right_sidebar_closed = request.cookies.get("rightSidebar") == "closed"
  left_sidebar_closed = request.cookies.get("leftSidebar") == "closed"
  return render_template('index.htmljinja', message_dict=message_dict, authed=g.authed,
      name_jumble=name_jumble, title=title, user_name=g.user['name'], avatar_url=g.user["gravatar"],
      channels=channels, last_selected_channel=last_selected_channel, render_template=render_template,
      markdown_renderer=markdown_renderer, right_sidebar_closed=right_sidebar_closed,
      left_sidebar_closed=left_sidebar_closed, datetime_to_unix=datetime_to_unix,
      time_window=current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"])

# A generator which yields combines subsequent messages from the same author within a given time window.
def collapsed_messages(messages):
  def render_message(message):
    return render_template("chat_message_partial.htmljinja",
                           message_id=message["_id"],
                           message=markdown_renderer.render(message["message"] or " "))
  def render_collapsed_messages():
    return render_template("chat_message.htmljinja",
                           merged_messages=True,
                           messages=collapsed_messages,
                           author=last_message["author"],
                           email=last_message["email"],
                           time=datetime_to_unix(last_message["datetime"]),
                           gravatar=last_message["gravatar"] or "static/anon.jpg")
  delta_seconds = lambda x,y: (x['datetime'] - y['datetime']).total_seconds()
  time_window = current_app.config["COLLAPSED_MESSAGE_TIME_WINDOW"]
  last_message = None
  collapsed_messages = None
  for message in messages:
    if last_message is None:
      last_message = message
      collapsed_messages = render_message(message)
    elif delta_seconds(message, last_message) > time_window or message["email"] != last_message["email"]:
      yield render_collapsed_messages()
      last_message = message
      collapsed_messages = render_message(message)
    else:
      last_message = message
      collapsed_messages += render_message(message)
  if last_message is not None:
    yield render_collapsed_messages()
