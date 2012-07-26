import zmq

context = zmq.Context()
pull_socket = context.socket(zmq.PULL)
pull_socket.bind("tcp://*:5555")
publish_socket = context.socket(zmq.PUB)
# TODO(kle): openpgm not supported on OS X 10.7
# publish_socket.bind("epgm://eth0;239.192.1.1:5555")
publish_socket.bind("tcp://*:5556")


while True:
  new_message = pull_socket.recv()
  print "received new message: {0}".format(new_message)
  publish_socket.send(new_message)
