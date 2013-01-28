#!/usr/env python

#TODO(kle): use config
from collections import namedtuple
import time
import zmq
import base64
import json
from redis import StrictRedis
from pymongo import MongoClient

def zmq_channel_key(channel_name):
  return base64.b64encode(channel_name.encode("utf-8"))

def send_user_offline(user, channel, socket):
  keyed_channel = zmq_channel_key(channel)
  event = { "action": "user_offline",
            "data": {
              "channel": channel,
              "user": {
                "email": user["email"],
                "gravatar": user["gravatar"],
                "status": "offline",
                "name": user["name"],
                "username": user["email"].split("@")[0],
              }
            }
          }
  packed_event = json.dumps(event)
  socket.send(" ".join([keyed_channel, packed_event]))

UserStatus = namedtuple("UserStatus", ["status", "channels"])

context = zmq.Context()
push_socket = context.socket(zmq.PUSH)
push_socket.connect("tcp://localhost:5666")
redis = StrictRedis()
mongo_client = MongoClient(tz_aware=True)
db = mongo_client.oochat

while True:
  user_channel_map = {}
  channels = (key.split(":")[1] for key in redis.keys("channel:*"))
  emails_to_check = []
  for channel in channels:
    for email, status in redis.hgetall("channel:" + channel).iteritems():
      if email not in user_channel_map:
        if status == "active":
          emails_to_check.append(email)
        user_channel_map[email] = UserStatus(status, [])
      user_channel_map[email].channels.append(channel)

  pipe = []
  for email in emails_to_check:
    num_clients = len(redis.keys("user-client:{0}:*".format(email)))
    if num_clients == 0:
      pipe.append((email, user_channel_map[email].channels))

  pipeline = redis.pipeline()
  for email, channels in pipe:
    user = db.users.find_one({ "email": email })
    for channel in channels:
      pipeline.hset("channel:" + channel, email, "offline")
      send_user_offline(user, channel, push_socket)
  pipeline.execute()
  time.sleep(30)
