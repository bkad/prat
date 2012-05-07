class window.Chat
  constructor: (@address) ->
    $(".chat-submit").click(@onChatSubmit)
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent

  onChatSubmit: =>
    message = $(".chat-text").val()
    @socket.send(message)
    $(".chat-text").val("")

  onEvent: (jsonMessage) =>
    bottom = @scrolledToBottom()
    messageObject = JSON.parse(jsonMessage.data)
    $(".chat-messages-container").append(messageObject["message"])
    @scrollToBottom() if bottom


  scrolledToBottom: ->
    messages = $(".chat-messages-container")
    difference = (messages[0].scrollHeight - messages.scrollTop()) is messages.outerHeight()
    return difference <= 1

  scrollToBottom: (animate=true) ->
    messages = $(".chat-messages-container")
    method = if animate then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight)
