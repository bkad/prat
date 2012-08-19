class window.MessageHub
  _.extend @::, Backbone.Events

  constructor: (@address, @reconnectTimeout, @alertHelper) ->
    @createSocket()

  createSocket: =>
    @socket?.close()
    @timeoutID = setTimeout(@createSocket, @reconnectTimeout)
    console.log "Connecting to #{@address}"
    @socket = new WebSocket(@address)
    @socket.onmessage = @onMessage
    @socket.onclose = @onConnectionFailed
    @socket.onopen = @onConnectionOpened

  onMessage: (message) =>
    messageObject = JSON.parse(message.data)
    @trigger(messageObject.action, messageObject.action, messageObject.data)

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
    clearTimeout(@timeoutID)
    @alertHelper.newAlert("alert-error", "Connection failed, reconnecting in #{@reconnectTimeout/1000} seconds")
    console.log "Connection failed, reconnecting in #{@reconnectTimeout/1000} seconds"
    setTimeout(@createSocket, @reconnectTimeout)

  onConnectionOpened: =>
    @alertHelper.delAlert()
    clearTimeout(@timeoutID)
    console.log "Connection successful"

  onConnectionTimedOut: =>
    @alertHelper.newAlert("alert-error", "Connection timed out")
    console.log "Connection timed out"
    @socket.close()


