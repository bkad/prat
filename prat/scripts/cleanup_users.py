# -*- coding: utf-8 -*-
"""
  prat.scripts.cleanup_users
  ~~~~~~~~~~~~~~~~~~~~~~~~~~

  Small process that sets users to "offline" if their user-client key has expired in Redis.

  This should handle the case when a WebSocket is closed from an unhandled exception or the webapp
  unexpectedly shuts down.

"""

from collections import namedtuple
import time
import re

from ..app import create_app
from ..datastore import (zmq_channel_key, db, redis_db, redis_channel_key, user_clients_key, get_user,
                         get_active_clients_count, get_user_statuses, set_user_channel_status)
from ..views.eventhub import send_user_status_update
from ..zmq_context import push_socket

keyspace_regex_string = "__keyspace@0__:{}.*".format(user_clients_key("(?P<email>[^:]*)"))
keyspace_regex = re.compile(keyspace_regex_string)

def extract_email(event):
  match = keyspace_regex.match(event)
  if match is None:
    raise ValueError("Keyspace event has no email")
  return match.groupdict()["email"]

def clean_users_loop():
  clean_users()
  pubsub = redis_db.pubsub()
  pubsub.psubscribe("__keyspace@0__:user-client:*")
  for item in pubsub.listen():
    if item["type"] != "pmessage" or item["data"] != "expired":
      continue
    try:
      email = extract_email(item["channel"])
    except ValueError:
      print "Failed to extract email from " + item
    if get_active_clients_count(email) == 0:
      send_user_offline(email, push_socket)

def send_user_offline(email, push_socket, pipe=None):
  "Starts a Redis Pub/Sub loop and listens for channel expiry events"
  user = get_user(email=email)
  for channel in user["channels"]:
    set_user_channel_status(user, channel, "offline", pipe=pipe)
    send_user_status_update(user, channel, push_socket, "offline")

def clean_users():
  "Does a one-time pass over users, cleaning up any which are now offline"

  email_status_map = {}
  channels = (key.split(":")[1] for key in redis_db.keys(redis_channel_key("") + "*"))
  emails_to_check = []
  for channel in channels:
    for email, status in get_user_statuses(channel):
      if email not in email_status_map:
        if status == "active":
          emails_to_check.append(email)
        email_status_map[email] = status

  pipeline = redis_db.pipeline()
  for email in emails_to_check:
    if get_active_clients_count(email) == 0:
      send_user_offline(email, push_socket, pipeline)
  pipeline.execute()
