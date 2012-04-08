from flask import Blueprint, request, g
import datetime
import geventwebsocket

eventhub = Blueprint("eventhub", __name__)

@eventhub.route('')
def eventhub_client():
  if request.environ.get('wsgi.websocket'):
    websocket = request.environ['wsgi.websocket']
    try:
      while True:
        message = websocket.receive()
        if message is None:
          break
        g.events.insert({ "author": "bkad",
                          "message": message,
                          "datetime": datetime.datetime.utcnow() })
        websocket.send(message)
    except geventwebsocket.WebSocketError, e:
      print "{0} {1}".format(e.__class__.__name__, e)
    websocket.close()
  return ""
