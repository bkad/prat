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
    messageObject = JSON.parse(jsonMessage.data)
    $(".chat-messages-container").append(messageObject["message"])

