window.Util =
  scrolledToBottom: ->
    messages = $(".chat-messages.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) - messages.outerHeight()
    difference <= 1

  scrollToBottom: (options = animate: true) ->
    messages = $(".chat-messages.current")
    scrollTop = messages[0].scrollHeight - messages.outerHeight() - 1
    if options.animate
      messages.animate(scrollTop: scrollTop, 150)
    else
      messages.prop(scrollTop: scrollTop)

  cleanupTipsy: -> $(".tipsy").remove()
