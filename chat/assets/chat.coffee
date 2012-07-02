class window.Chat
  constructor: (@address, @reconnectTimeout) ->

  init: ->
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-text").on("keyup.ctrl_return", @onChatSubmit)
    @createSocket()

  createSocket: =>
    @timeoutID = setTimeout(@createSocket, @reconnectTimeout)
    console.log "Connecting to #{@address}"
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent
    @socket.onclose = @onConnectionFailed
    @socket.onopen = @onConnectionOpened

  sendSwitchChannelEvent: (channel) =>
    @socket.send(JSON.stringify({"action":"switch_channel", "data":{"channel":channel}}))

  onChatSubmit: =>
    message = $(".chat-text").val()
    channel = @channelControls.currentChannel
    @socket.send(JSON.stringify({"action":"publish_message", "data":{"message":message, "channel":channel}}))
    $(".chat-text").val("").focus()

  onEvent: (jsonMessage) =>
    bottom = @scrolledToBottom()
    socketObject = JSON.parse(jsonMessage.data)
    action = socketObject["action"]
    data = socketObject["data"]
    @appendMessage(data["message"], data["channel"]) if action is "message"

    @scrollToBottom() if bottom

  appendMessage: (message, channel) =>
    findEmail = (message) -> message.find(".email").text()
    message = $(message)
    messagesContainer = $(".chat-messages-container[data-channel='#{channel}']")
    lastMessage = messagesContainer.find(".message-container").last()

    # if the author of consecutive messages are the same, collapse them
    if findEmail(lastMessage) is findEmail(message)
      message.find(".message").appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", message.find(".time").attr("data-time"))
      @dateTimeHelper.removeBindings(timeContainer)
    else
      message.appendTo(messagesContainer)
      timeContainer = message.find(".time")
    @dateTimeHelper.bindOne(timeContainer)
    @dateTimeHelper.updateTimestamp(timeContainer)

  onConnectionFailed: =>
    clearTimeout(@timeoutID)
    console.log "Connection failed, reconnecting in #{@reconnectTimeout/1000} seconds"
    setTimeout(@createSocket, @reconnectTimeout)

  onConnectionOpened: =>
    clearTimeout(@timeoutID)
    console.log "Connection successful"

  onConnectionTimedOut: =>
    console.log "Connection timed out"
    @socket.close()

  scrolledToBottom: ->
    messages = $(".chat-messages-container.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) is messages.outerHeight()
    return difference <= 1

  scrollToBottom: (animate=true) ->
    messages = $(".chat-messages-container.current")
    method = if animate then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight)

  setChannelControls: (channelControls) -> @channelControls = channelControls
  setDateTimeHelper: (dateTimeHelper) -> @dateTimeHelper = dateTimeHelper
