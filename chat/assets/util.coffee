window.Util =
  scrolledToBottom: ->
    messages = $(".chat-messages-container.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) is messages.outerHeight()
    difference <= 1

  scrollToBottom: (animate = "animate") ->
    messages = $(".chat-messages-container.current")
    method = if animate == "animate" then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight)
