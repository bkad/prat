import werkzeug.serving
from geventwebsocket.handler import WebSocketHandler
from gevent.pywsgi import WSGIServer
from chat import create_app


@werkzeug.serving.run_with_reloader
def run_server():
  app = create_app()
  http_server = WSGIServer(('0.0.0.0',5000), app, handler_class=WebSocketHandler)
  http_server.serve_forever()

if __name__ == "__main__":
  run_server()
