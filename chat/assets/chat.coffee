class window.Chat
  constructor: (@address, @reconnectTimeout, @collapseTimeWindow) ->

  init: ->
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
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
    bottom = Util.scrolledToBottom()
    socketObject = JSON.parse(jsonMessage.data)
    action = socketObject["action"]
    @appendMessage(socketObject["data"]) if action is "message"

    Util.scrollToBottom("animate") if bottom

  appendInitialMessages: (messageDict) =>
    for channel, messages of messageDict
      for message in messages
        @appendMessage(message)

  # following three functions are helpers for @appendMessage
  findMessageEmail: (message) -> message.find(".email").text()
  findMessageTime: (message) -> parseInt(message.find(".time").attr("data-time"))
  newMessageInTimeWindow: (recentMessage, oldMessage) =>
    # recentMessage: a javascript object (received from the server socket connection)
    # oldMessage: a JQuery object (from the DOM)
    (recentMessage["datetime"] - @findMessageTime(oldMessage)) <= @collapseTimeWindow

  appendMessage: (message) =>
    messagesList = $(".chat-messages-container[data-channel='#{message["channel"]}']")
    lastMessage = messagesList.find(".message-container").last()
    $message = $(Mustache.render(@messagePartialTemplate, message))

    # if the author of consecutive messages are the same, collapse them
    if @findMessageEmail(lastMessage) is message["email"] and @newMessageInTimeWindow(message, lastMessage)
      $message.appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", message["datetime"])
      @dateTimeHelper.removeBindings(timeContainer)
    else
      $messageContainer = $(Mustache.render(@messageContainerTemplate, message))
      $messageContainer.filter(".message-container").append($message)
      $messageContainer.appendTo(messagesList)
      timeContainer = $messageContainer.find(".time")
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

  setChannelControls: (channelControls) -> @channelControls = channelControls
  setDateTimeHelper: (dateTimeHelper) -> @dateTimeHelper = dateTimeHelper
