class window.Chat
  constructor: (@address, @reconnectTimeout, @collapseTimeWindow) ->

  init: ->
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-text").on("keydown.return", @onChatSubmit)
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

  onChatSubmit: (event) =>
    message = $(".chat-text").val()
    if message.replace(/\s*$/, "") isnt ""
      channel = @channelControls.currentChannel
      messageObject =
        action: "publish_message"
        data:
          message: message
          channel: channel
      @socket.send(JSON.stringify(messageObject))
    $(".chat-text").val("").focus()
    event.preventDefault()

  onEvent: (jsonMessage) =>
    bottom = @scrolledToBottom()
    socketObject = JSON.parse(jsonMessage.data)
    action = socketObject["action"]
    data = socketObject["data"]
    @appendMessage(data["message"], data["channel"]) if action is "message"

    @scrollToBottom() if bottom

  appendMessage: (message, channel) =>
    findEmail = (message) -> message.find(".email").text()
    getMessageTime = (message) -> parseInt(message.find(".time").attr("data-time"))
    newMessageInTimeWindow = (recentMessage, oldMessage) =>
      (getMessageTime(recentMessage) - getMessageTime(oldMessage)) <= @collapseTimeWindow
    message = $(message)
    messagesContainer = $(".chat-messages-container[data-channel='#{channel}']")
    lastMessage = messagesContainer.find(".message-container").last()

    # if the author of consecutive messages are the same, collapse them
    if findEmail(lastMessage) is findEmail(message) and newMessageInTimeWindow(message, lastMessage)
      message.find(".message").appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", getMessageTime(message))
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
