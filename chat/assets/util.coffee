window.Util =
  scrolledToBottom: ->
    messages = $(".chat-messages.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) - messages.outerHeight()
    difference <= 1

  scrollToBottom: (options = animate: true) ->
    messages = $(".chat-messages.current")
    method = if options.animate then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight - messages.outerHeight() - 1)

  cleanupTipsy: -> $(".tipsy").remove()
