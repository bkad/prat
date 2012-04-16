import pymongo
from flask import Blueprint, g, render_template
import time

frontend = Blueprint("frontend", __name__)

@frontend.route('/')
def index():
  messages = g.events.find().sort("$natural", pymongo.DESCENDING).limit(100)
  return render_template('index.htmljinja', messages=messages, time=time)
