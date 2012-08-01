import werkzeug.serving
from geventwebsocket.handler import WebSocketHandler
from gevent.pywsgi import WSGIServer
from chat import create_app

# TODO(kle): temporary fix for evicting client orphan ids until GH-42 is resolved
def remove_all_client_ids(app):
  from chat.datastore import redis_db, user_clients_key
  with app.app_context():
    clients_key_prefix = user_clients_key({ "email": "" })
    for key in redis_db.keys(clients_key_prefix + "*"):
      redis_db.delete(key)

# TODO(kle): remove once we've gated on authentication
def remove_all_anonymous_users_from_channels(app):
  from chat.datastore import redis_db, redis_channel_key
  with app.app_context():
    channel_key_prefix = redis_channel_key("")
    for key in redis_db.keys(channel_key_prefix + "*"):
      for email, status in redis_db.hgetall(key).iteritems():
        if "@" not in email and status == "offline":
          redis_db.hdel(key, email)

@werkzeug.serving.run_with_reloader
def run_server():
  app = create_app()
  remove_all_client_ids(app)
  remove_all_anonymous_users_from_channels(app)
  http_server = WSGIServer(('0.0.0.0',5000), app, handler_class=WebSocketHandler)
  http_server.serve_forever()

if __name__ == "__main__":
  run_server()
