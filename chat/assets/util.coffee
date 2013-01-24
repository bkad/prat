window.Util =
  scrollingToBottom: 0
  scrolling: 0

  scrolledToBottom: ->
    # if a scrolling animation is taking place, we are at the bottom
    return true if @scrollingToBottom > 0
    messages = $(".chat-messages.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) - messages.outerHeight()
    difference <= 1

  scrollMessagesUp: (options = animate: true) ->
    messageList = $(".chat-messages.current")
    messages = $(messageList.children().filter(".message-container"))
    if messages.length == 0
      return
    firstOffScreenMessage = $(messages[0])
    # Find first message that is partially scrolled off the top of the messages view
    for i in [messages.length - 1..0] by -1
      if $(messages[i]).offset().top + messageList.offset().top <= 0
        firstOffScreenMessage = $(messages[i])
        break
    if options.animate
      @scrolling += 1
      messageList.scrollTo(firstOffScreenMessage, duration: 150, {margin: true, onAfter: -> Util.scrolling -= 1})
    else
      messageList.scrollTo(firstOffScreenMessage)

  scrollMessagesDown: (options = animate: true) ->
    messageList = $(".chat-messages.current")
    messages = $(messageList.children().filter(".message-container"))
    if messages.length == 0
      return
    firstOffScreenMessage = $(messages[messages.length-1])
    # Find first message that rolls off the bottom of the messages view
    for i in [0..messages.length - 1]
      if $(messages[i]).offset().top + $(messages[i]).outerHeight() >= messageList.offset().top + messageList.outerHeight()
        firstOffScreenMessage = $(messages[i])
        break
    if firstOffScreenMessage[0] == $(messages[messages.length-1])[0]
      Util.scrollToBottom()
    else
      # place the bottom of the message just above the bottom of the message view
      difference = -messageList.outerHeight() + $(messages[i]).outerHeight(true)
      if options.animate
        @scrolling += 1
        offset = {top:difference, left:0}
        messageList.scrollTo(firstOffScreenMessage, {offset:offset, duration:150, margin: true, onAfter: -> Util.scrolling -= 1})
      else
        messageList.scrollTo(firstOffScreenMessage, { offset:{top:-10, left:0} })

  scrollToBottom: (options = animate: true) ->
    messages = $(".chat-messages.current")
    scrollTop = messages[0].scrollHeight - messages.outerHeight() - 1
    if options.animate
      @scrollingToBottom += 1
      messages.animate({ scrollTop: scrollTop }, duration: 150, complete: -> Util.scrollingToBottom -= 1)
    else
      messages.prop(scrollTop: scrollTop)

  cleanupTipsy: -> $(".tipsy").remove()
