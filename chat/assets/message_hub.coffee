class window.MessageHub
  _.extend @::, Backbone.Events

  constructor: (@address, @reconnectTimeout, @pingInterval, @alertHelper) ->
    @timeoutIDs = []
    @pingIDs = []
    @queueing = false
    @reconnect = false
    @queue = []

    # tracks the number of listeners who care about reconnect events and have to check in before a dequeue
    # can happen
    @blockingDequeue = 0
    @currentlyBlockingDequeue = 0

  init: =>
    @createSocket()

  createSocket: =>
    @socket?.close()
    @pingIDs = []
    clearInterval(pingID) for pingID in @pingIDs
    @timeoutIDs.push(setTimeout(@createSocket, @reconnectTimeout))
    console.log "Connecting to #{@address}"
    @socket = new WebSocket(@address)
    @socket.onmessage = @onMessage
    @socket.onclose = @onConnectionFailed
    @socket.onopen = @onConnectionOpened

  onMessage: (message) =>
    messageObject = JSON.parse(message.data)
    if @queueing
      @queue.push(messageObject)
    else
      @trigger(messageObject.action, messageObject.action, messageObject.data)

  unblockDequeue: =>
    @currentlyBlockingDequeue -= 1
    if @currentlyBlockingDequeue <= 0
      @trigger(message.action, message.action, message.data) for message in @queue
      @queue = []
      @queueing = false

  sendJSON: (messageObject) => @socket.send(JSON.stringify(messageObject))

  reorderChannels: (channels) =>
    @sendJSON
      action: "reorder_channels"
      data:
        channels: channels

  switchChannel: (channel) =>
    @sendJSON
      action: "switch_channel"
      data:
        channel: channel

  sendPreview: (message, channel) =>
    @sendJSON
      action: "preview_message"
      data:
        message: message
        channel: channel

  sendChat: (message, channel) =>
    @sendJSON
      action: "publish_message"
      data:
        message: message
        channel: channel

  leaveChannel: (channel) =>
    @sendJSON
      action: "leave_channel"
      data:
        channel: channel

  joinChannel: (channel) =>
    @sendJSON
      action: "join_channel"
      data:
        channel: channel

  onConnectionFailed: =>
    @reconnect = true
    @currentlyBlockingDequeue = @blockingDequeue
    @clearAllTimeoutIDs()
    @alertHelper.newAlert("alert-error", "Connection failed, reconnecting in #{@reconnectTimeout/1000} seconds")
    console.log "Connection failed, reconnecting in #{@reconnectTimeout/1000} seconds"
    @timeoutIDs.push(setTimeout(@createSocket, @reconnectTimeout))

  onConnectionOpened: =>
    @alertHelper.delAlert()
    @clearAllTimeoutIDs()
    @pingIDs.push(setInterval(@keepAlive, @pingInterval))
    @trigger("reconnect") if @reconnect
    @reconnect = false
    console.log "Connection successful"

  keepAlive: =>
    @sendJSON
      action: "ping"
      data:
        message: "PING"

  clearAllTimeoutIDs: =>
    clearTimeout(timeoutID) for timeoutID in @timeoutIDs
    @timeoutIDs = []

  blockDequeue: =>
    @blockingDequeue += 1
