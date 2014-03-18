# -*- coding: utf-8 -*-
"""
  chat.scripts.event_server
  ~~~~~~~~~~~~~~~~~~~~~~~~~

  Implements the PubSub server where all events are funnelled through.

"""

import zmq
from .utils import get_config_from_argv

def run_event_server(config):
  context = zmq.Context()
  pull_socket = context.socket(zmq.PULL)
  pull_socket.bind(config.PULL_ADDRESS)
  publish_socket = context.socket(zmq.PUB)
  # TODO(kle): openpgm not supported on OS X 10.7
  # publish_socket.bind("epgm://eth0;239.192.1.1:5555")
  publish_socket.bind(config.PUBLISH_ADDRESS)

  while True:
    new_message = pull_socket.recv()
    publish_socket.send(new_message)

if __name__ == "__main__":
  run_event_server(get_config_from_argv())
