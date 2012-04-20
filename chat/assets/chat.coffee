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
    newMessage = "<div class=\"message\">" +
      "<div class=\"message-author\">#{messageObject["author"]}</div>" +
      "<div class=\"message-contents\">#{messageObject["message"]}</div>" +
      "</div>"
      $(".chat-messages-container").append(newMessage)

