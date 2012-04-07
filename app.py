import pymongo
import geventwebsocket
from geventwebsocket.handler import WebSocketHandler
from gevent.pywsgi import WSGIServer
from flask import Flask, request, render_template, make_response, abort, g
from stylus import Stylus
import coffeescript
import mimetypes
from os import path
import datetime
import werkzeug.serving
import gevent.monkey
# line added to make the reloader work
gevent.monkey.patch_all()

DEBUG = True
MONGO_HOST = "127.0.0.1"
MONGO_PORT = 27017
MONGO_DB_NAME = "oochat"
COMPILED_ASSET_PATH = "assets"

app = Flask(__name__)
app.config.from_object(__name__)
app.config.from_pyfile("settings.py", silent=True)

@app.before_request
def before_request():
  g.css_compiler = Stylus(plugins={"nib":{}})
  g.mongo = pymongo.Connection(host=app.config["MONGO_HOST"], port=app.config["MONGO_PORT"], tz_aware=True)

@app.errorhandler(404)
def page_not_found(error):
  return render_template('404.htmljinja'), 404

@app.route('/')
def index():
  return render_template('index.htmljinja')

@app.route('/assets/<path:asset_path>')
def assets(asset_path):
  asset_path = path.join(app.config["COMPILED_ASSET_PATH"], asset_path)
  if not path.exists(asset_path):
    abort(404)
  with open(asset_path) as fp:
    file_contents = fp.read()
  if asset_path.endswith(".styl"):
    response = make_response(g.css_compiler.compile(file_contents))
    response.headers["Content-Type"] = "text/css"
  elif asset_path.endswith(".coffee"):
    response = make_response(coffeescript.compile(file_contents))
    response.headers["Content-Type"] = "application/javascript"
  else:
    response = make_response(file_contents)
    content_tuple = mimetypes.guess_type(asset_path)
    content_type = content_tuple[0] or "text/plain"
    response.headers["Content-Type"] = content_type
  return response

@app.route('/api')
def api():
  if request.environ.get('wsgi.websocket'):
    ws = request.environ['wsgi.websocket']
    try:
      while True:
        message = ws.receive()
        g.mongo.events.insert({ "author": "bkad",
                                "message": message,
                                "datetime": datetime.datetime.utcnow() })
        ws.send(message)
    except geventwebsocket.WebSocketError, e:
      print "{0} {1}".format(e.__class__.__name__, e)
  return ""

@werkzeug.serving.run_with_reloader
def run_server():
  http_server = WSGIServer(('',5000), app, handler_class=WebSocketHandler)
  http_server.serve_forever()


if __name__ == '__main__':
  run_server()
