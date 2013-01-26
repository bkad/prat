window.Util =
  scrollingToBottom: 0
  scrolling: 0

  scrolledToBottom: ->
    # if a scrolling animation is taking place, we are at the bottom
    return true if @scrollingToBottom > 0
    messages = $(".chat-messages.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) - messages.outerHeight()
    difference <= 1

  scrollMessagesUp: (options = animate: true) =>
    messageList = $(".chat-messages.current")
    messages = $(messageList.children().filter(".message-container"))

    # Return quickly if there's no chance of scrolling
    if messages.length == 0
      return

    # Assume we're scrolling to the top most message by default
    firstOffScreenMessage = $(messages[0])

    # Find first message that is partially scrolled off the top of the messages view
    for i in [messages.length - 1..0] by -1
      if $(messages[i]).offset().top + messageList.offset().top <= 0
        firstOffScreenMessage = $(messages[i])
        break

    # Scroll to message
    if options.animate
      @scrolling += 1
      messageList.scrollTo(firstOffScreenMessage, {duration: 50, margin: true, onAfter: -> Util.scrolling -= 1})
    else
      messageList.scrollTo(firstOffScreenMessage, { margin: true } )

  scrollMessagesDown: (options = animate: true) =>
    messageList = $(".chat-messages.current")
    messages = $(messageList.children().filter(".message-container"))

    # Return quickly if there's no chance of scrolling
    if messages.length == 0
      return

    # Assume we're scrolling to bottom most message by default
    firstOffScreenMessage = $(messages[messages.length-1])

    # Find first message that is scrolled off the bottom of the messages view
    for i in [0..messages.length - 1]
      bottomOfMessageView = messageList.offset().top + messageList.outerHeight()
      bottomEdgeOfMessage = $(messages[i]).offset().top + $(messages[i]).outerHeight()

      if bottomEdgeOfMessage >= bottomOfMessageView
        firstOffScreenMessage = $(messages[i])
        break

    # If we're scrolling to the bottom most message, just scroll to the very bottom
    if firstOffScreenMessage[0] == $(messages[messages.length-1])[0]
      Util.scrollToBottom(animate: options.animate)
    else
      # place the bottom of the message just above the bottom of the message view
      difference = -messageList.outerHeight() + $(messages[i]).outerHeight(true)
      offset = {top:difference, left:0}

      # Scroll to message
      if options.animate
        @scrolling += 1
        messageList.scrollTo(firstOffScreenMessage, {offset:offset, duration: 50, margin: true, onAfter: -> Util.scrolling -= 1})
      else
        messageList.scrollTo(firstOffScreenMessage, { offset:offset, margin: true })

  scrollToBottom: (options = animate: true) ->
    messages = $(".chat-messages.current")
    scrollTop = messages[0].scrollHeight - messages.outerHeight() - 1
    if options.animate
      @scrollingToBottom += 1
      messages.animate({ scrollTop: scrollTop }, duration: 150, complete: -> Util.scrollingToBottom -= 1)
    else
      messages.prop(scrollTop: scrollTop)

  cleanupTipsy: -> $(".tipsy").remove()

  spinConfig:
    lines: 11,            # The number of lines to draw
    length: 13,           # The length of each line
    width: 4,             # The line thickness
    radius: 24,           # The radius of the inner circle
    corners: 1,           # Corner roundness (0..1)
    rotate: 14,           # The rotation offset
    color: "#4782B4",     # accent-blue
    speed: 1.4,           # Rounds per second
    trail: 100,           # Afterglow percentage
    shadow: false,        # Whether to render a shadow
    hwaccel: false,       # Whether to use hardware acceleration
    className: 'spinner', # The CSS class to assign to the spinner
    zIndex: 2e9,          # The z-index (defaults to 2000000000)
    top: 'auto',          # Top position relative to parent in px
    left: 'auto'          # Left position relative to parent in px

window.onbeforeunload = ->
  if $("#chat-text").val().length > 0
    return "You have an unsent message."
