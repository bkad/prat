window.Util =
  scrollingToBottom: 0
  scrolling: 0
  currScroll: 0

  scrolledToBottom: ->
    # if a scrolling animation is taking place, we are at the bottom
    return true if @scrollingToBottom > 0
    messages = $(".chat-messages.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) - messages.outerHeight()
    difference <= 1

  scrollUpToMessage: (message, options = animate: true) ->
    messages = $(".chat-messages.current")
    @currScroll = @currScroll - $(message).outerHeight(true) - 1
    console.log(@currScroll)
    if options.animate
        @scrolling += 1
        messages.animate({ scrollTop: @currScroll }, duration: 150, complete: -> Util.scrolling -= 1)
      else
        messages.prop(scrollTop: @currScroll)

  scrollDownToMessage: (message, options = animate: true) ->
    messages = $(".chat-messages.current")
    @currScroll = @currScroll + $(message).outerHeight(true) + 1
    console.log(@currScroll)
    if options.animate
      @scrolling += 1
      messages.animate({ scrollTop: @currScroll }, duration: 150, complete: -> Util.scrolling -= 1)
    else
      messages.prop(scrollTop: @currScroll)

  scrollToBottom: (options = animate: true) ->
    messages = $(".chat-messages.current")
    scrollTop = messages[0].scrollHeight - messages.outerHeight() - 1
    if options.animate
      @scrollingToBottom += 1
      messages.animate({ scrollTop: scrollTop }, duration: 150, complete: -> Util.scrollingToBottom -= 1)
    else
      messages.prop(scrollTop: scrollTop)
    @currScroll = scrollTop

  cleanupTipsy: -> $(".tipsy").remove()
