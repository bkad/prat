import pymongo
from flask import Blueprint, g, render_template

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  messages = g.events.find().sort("$natural", pymongo.DESCENDING).limit(8)
  return render_template('index.htmljinja', messages=messages)
