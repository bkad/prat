import sys

from geventwebsocket.handler import WebSocketHandler
from gevent.pywsgi import WSGIServer
import werkzeug.serving

from ..app import create_app

def run_app_server(config):
  def run():
    app = create_app(config)
    http_server = WSGIServer(('0.0.0.0',5000), app, handler_class=WebSocketHandler)
    sys.stderr.write("Now serving on port 5000...\n")
    sys.stderr.flush()
    http_server.serve_forever()
  werkzeug.serving.run_with_reloader(run)
