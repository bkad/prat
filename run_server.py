import werkzeug.serving
from geventwebsocket.handler import WebSocketHandler
from gevent.pywsgi import WSGIServer
from chat import create_app

# temporary fix for evicting client orphan ids until GH-42 is resolved
def remove_all_client_ids(app):
  from chat.datastore import redis_db, user_clients_key
  with app.app_context():
    clients_key_prefix = user_clients_key({ "email": "" })
    for key in redis_db.keys(clients_key_prefix + "*"):
      redis_db.delete(key)

@werkzeug.serving.run_with_reloader
def run_server():
  app = create_app()
  remove_all_client_ids(app)
  http_server = WSGIServer(('0.0.0.0',5000), app, handler_class=WebSocketHandler)
  http_server.serve_forever()

if __name__ == "__main__":
  run_server()
