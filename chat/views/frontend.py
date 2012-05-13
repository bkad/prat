import pymongo
from flask import Blueprint, g, render_template, request
from chat.tardis import datetime_to_unix
from random import shuffle
from chat.markdown import markdown_renderer
from collections import OrderedDict

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  channels = g.user["channels"]
  message_dict = OrderedDict()
  for channel in channels:
    message_dict[channel] = g.events.find({"channel":channel}).sort("$natural", pymongo.DESCENDING).limit(100)
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
      left_sidebar_closed=left_sidebar_closed, datetime_to_unix=datetime_to_unix)
