angular.module("prat.services.eventHub", [])
.factory "eventHub", ($q) ->
  class EventHub
    _.extend @::, Backbone.Events

    constructor: (config) ->
      @address = config.address
      @reconnectTimeout = config.reconnectTimeout
      @pingInterval = config.pingInterval

      # Track the number of listeners who listen to reconnect events and have to check in before events can dequeue
      @blockingDequeue: []
      @timeoutIDs: []
      @pingIDs: []
      @queueing: true
      @reconnect: false
      @queue: []

      @createSocket()

    @createSocket: =>
      @socket?.close()
      @pingIDs = []
      clearInterval(pingID) for pingID in @pingIDs
      @timeoutIDs.push(setTimeout(@createSocket, @reconnectTimeout))
      console.log "Connecting to #{@address}"
      @socket = new WebSocket(@address)
      @socket.onmessage = @onMessage
      @socket.onclose = @onConnectionFailed
      @socket.onopen = @onConnectionOpened

    @onMessage: (message) =>
      messageObject = JSON.parse(message.data)
      if @queueing
        @queue.push(messageObject)
      else
        @trigger(messageObject.action, messageObject.action, messageObject.data)

    @onReconnect: (callback) =>
      @blockingDequeue.push(callback)

    @dequeue: =>
      @trigger(message.action, message.action, message.data) for message in @queue
      @queue = []
      @queueing = false

    @sendJSON: (messageObject) => @socket.send(JSON.stringify(messageObject))

    @reorderChannels: (channels) =>
      @sendJSON
        action: "reorder_channels"
        data:
          channels: channels

    @switchChannel: (channel) =>
      @sendJSON
        action: "switch_channel"
        data:
          channel: channel

    @sendPreview: (message, channel) =>
      @sendJSON
        action: "preview_message"
        data:
          message: message
          channel: channel

    @sendChat: (message, channel) =>
      @sendJSON
        action: "publish_message"
        data:
          message: message
          channel: channel

    @leaveChannel: (channel) =>
      @sendJSON
        action: "leave_channel"
        data:
          channel: channel

    @joinChannel: (channel) =>
      @sendJSON
        action: "join_channel"
        data:
          channel: channel

    @onConnectionFailed: =>
      @reconnect = true
      @clearAllTimeoutIDs()
      @trigger("connection-failed", "connection-failed", @reconnectTimeout/1000)
      @timeoutIDs.push(setTimeout(@createSocket, @reconnectTimeout))

    @onConnectionOpened: =>
      @alertHelper.delAlert()
      @clearAllTimeoutIDs()
      @pingIDs.push(setInterval(@keepAlive, @pingInterval))
      @deferDequeue(@blockingDequeue...) if @reconnect
      @reconnect = false
      console.log "Connection successful"

    @keepAlive: =>
      @sendJSON
        action: "ping"
        data:
          message: "PING"

    @clearAllTimeoutIDs: =>
      clearTimeout(timeoutID) for timeoutID in @timeoutIDs
      @timeoutIDs = []

    # When connected, queue events and wait for backfilling to finish before dequeuing
    @deferDequeue: (callbacks...) =>
      $q.all(callback.call() for callback in callbacks)
       .then(@dequeue, @dequeue)


  websocketProtocol = if "https:" is document.location.protocol then "wss" else "ws"
  new EventHub
    address: "#{websocketProtocol}://#{document.location.host}/eventhub"
    reconnectTimeout: 4000
    pingInterval: Initial.websocket_keep_alive_interval
