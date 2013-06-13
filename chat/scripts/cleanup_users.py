# -*- coding: utf-8 -*-
"""
  chat.scripts.cleanup_users
  ~~~~~~~~~~~~~~~~~~~~~~~~~

  Small process that sets users to "offline" if their user-client key has expired in Redis.

  This should handle the case when a WebSocket is closed from an unhandled exception or the webapp
  unexpectedly shuts down.

"""

from collections import namedtuple
import time
from ..datastore import (zmq_channel_key, db, redis_db, redis_channel_key, user_clients_key, get_user,
    get_active_clients_count, get_user_statuses, set_user_channel_status)
from ..app import create_app
from ..zmq_context import push_socket
from .utils import get_config_or_exit
from ..views.eventhub import send_user_status_update

UserStatus = namedtuple("UserStatus", ["status", "channels"])

def run_clean_users():
  while True:
    user_channel_map = {}
    channels = (key.split(":")[1] for key in redis_db.keys(redis_channel_key("") + "*"))
    emails_to_check = []
    for channel in channels:
      for email, status in get_user_statuses(channel):
        if email not in user_channel_map:
          if status == "active":
            emails_to_check.append(email)
          user_channel_map[email] = UserStatus(status, [])
        user_channel_map[email].channels.append(channel)

    pipe = []
    for email in emails_to_check:
      num_clients = get_active_clients_count(email)
      if num_clients == 0:
        pipe.append((email, user_channel_map[email].channels))

    pipeline = redis_db.pipeline()
    for email, channels in pipe:
      user = get_user(email=email)
      for channel in channels:
        set_user_channel_status(user, channel, "offline", pipe=pipeline)
        send_user_status_update(user, channel, push_socket, "offline")
    pipeline.execute()
    time.sleep(30)

if __name__ == "__main__":
  config = get_config_or_exit()
  app = create_app(config)
  with app.test_request_context():
    run_clean_users()
