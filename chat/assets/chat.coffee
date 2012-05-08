class window.Chat
  constructor: (@address) ->
    $(".chat-submit").click(@onChatSubmit)
    $(".switch-channel").click(@onSwitchChannel)
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent

  onSwitchChannel: =>
    channel = document.location.hash.substring(1)
    @socket.send(JSON.stringify({"action":"switch_channel", "data":{"channel":channel}}))

  onChatSubmit: =>
    message = $(".chat-text").val()
    channel = document.location.hash
    if channel.length >= 0
      channel = channel.substring(1)
    @socket.send(JSON.stringify({"action":"publish_message", "data":{"message":message, "channel":channel}}))
    $(".chat-text").val("")

  onEvent: (jsonMessage) =>
    bottom = @scrolledToBottom()
    socketObject = JSON.parse(jsonMessage.data)
    action = socketObject["action"]
    data = socketObject["data"]
    if action == "switch_channel"
      $(".chat-messages-container").children().remove()
      $(".chat-messages-container").append(message) for message in data["messages"]
    if action == "message"
      $(".chat-messages-container").append(data["message"])
    @scrollToBottom() if bottom


  scrolledToBottom: ->
    messages = $(".chat-messages-container")
    difference = (messages[0].scrollHeight - messages.scrollTop()) is messages.outerHeight()
    return difference <= 1

  scrollToBottom: (animate=true) ->
    messages = $(".chat-messages-container")
    method = if animate then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight)
