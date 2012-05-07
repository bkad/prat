class window.Chat
  constructor: (@address) ->
    $(".chat-submit").click(@onChatSubmit)
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent

  onChatSubmit: =>
    message = $(".chat-text").val()
    author = $.trim($(".user-name").text())
    message_obj =
      message: message
      author: author
    @socket.send(JSON.stringify(message_obj))
    $(".chat-text").val("")

  onEvent: (jsonMessage) =>
    messageObject = JSON.parse(jsonMessage.data)
    $(".chat-messages-container").append(messageObject["message"])

