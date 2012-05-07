import pymongo
from flask import Blueprint, g, render_template
import time
from random import shuffle
from chat.markdown import markdown_renderer

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  messages = g.events.find().sort("$natural", pymongo.DESCENDING).limit(100)
  # maybe use backchat, flexjaxlot (it lines it up nicely)
  name_jumble = ["back", "flex", "jax", "chat", "lot"]
  shuffle(name_jumble)
  title = "".join(name_jumble)
  avatar_url = "static/anon.jpg"
  return render_template('index.htmljinja', messages=messages, time=time, name_jumble=name_jumble,
      title=title, user_name=g.user['name'], avatar_url=avatar_url, authed=g.authed, render_template=render_template, markdown_renderer=markdown_renderer )