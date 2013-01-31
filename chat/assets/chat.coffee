class window.MessageNotification extends Backbone.View

  tagname: "div"
  className: "message-notification"

  initialize: (options) ->
    @chatControls = options.chatControls
    $(".input-container").before(@$el)

  activate: =>
    @$el.addClass("active")

  deactivate: =>
    @$el.removeClass("active")

class window.MessagesView extends Backbone.View
  tagName: "div"
  className: "chat-messages"
  events: {"scroll": "handleMouseScroll"}

  initialize: (options) ->
    @notifier = options.notifier

  handleMouseScroll: =>
    if Util.scrolledToBottom()
      @notifier.deactivate()

class window.MessagesViewCollection extends Backbone.View
  tagName: "div"
  className: "chat-messages-container"

  initialize: (options) =>
    @channelHash = {}
    @channels = options.channels
    @collapseTimeWindow = options.collapseTimeWindow
    @dateTimeHelper = options.dateTimeHelper
    @username = options.username
    @sound = options.sound
    @title = options.title
    @chatControls = options.chatControls
    @messageHub = options.messageHub
    # latest in terms of date time stamp
    @latestMessage = datetime: 0
    @channelViewCollection = options.channelViewCollection
    $(".input-container").before(@$el)
    @notifier = new MessageNotification({chatControls:@chatControls})
    @messageHub.on("publish_message", @onNewMessage)
               .on("preview_message", @onPreviewMessage)
               .on("reconnect", @pullMissingMessages)
    @messageHub.blockDequeue()
    @channelViewCollection.on("changeCurrentChannel", @changeCurrentChannel)
                          .on("leaveChannel", @removeChannel)
                          .on("joinChannel", @addChannel)
    @chatControls.on("scrollToBottom", @scrollToBottom)
    @chatControls.on("scrollMessagesUp", @scrollMessagesUp)
    @chatControls.on("scrollMessagesDown", @scrollMessagesDown)
    for channel in options.channels
      view = @channelHash[channel] = new MessagesView({notifier:@notifier})
      if channel is @channelViewCollection.currentChannel
        view.$el.addClass("current")
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
    @render()

  render: =>
    @$el.children().detach()
    @$el.append(@channelHash[channel].$el) for channel in @channels

  scrollToBottom: (options = animate: true) =>
    if not Util.scrolledToBottom()
      @notifier.deactivate()
      Util.scrollToBottom(options)

  scrollMessagesUp: (options = animate: true) =>
    Util.scrollMessagesUp()

  scrollMessagesDown: (options = animate: true) =>
    if Util.scrollMessagesDown()
      @notifier.deactivate()

  addChannel: (channel) =>
    @channelHash[channel] = new MessagesView()
    @$el.append(@channelHash[channel].$el)
    $.ajax
      url: "/api/messages/#{encodeURIComponent(channel)}"
      dataType: "json"
      success: (messages) =>
        @appendMessages(messages, quiet: true)

  removeChannel: (channel) =>
    @channelHash[channel].$el.remove()
    delete @channelHash[channel]

  changeCurrentChannel: (newChannel) =>
    view.$el.removeClass("current") for channel, view of @channelHash
    @channelHash[newChannel].$el.addClass("current")
    @scrollToBottom(animate: false)

  checkAndNotify: (message, author) =>
    if !document.hasFocus() or document.webkitHidden
      @lastAuthor = author
      unless @toggleTitleInterval?
        @toggleTitleInterval = setInterval(@toggleTitle, 1500)
      window.onfocus = @clearToggleTitleInterval
      if message.find(".its-you").length > 0
        @sound.playNewMessageAudio()

  clearToggleTitleInterval: =>
    window.onfocus = null
    clearInterval(@toggleTitleInterval)
    @toggleTitleInterval = null
    $("title").html(@title)
    @showingTitle = true

  toggleTitle: =>
    newTitle = if @showingTitle then "#{@lastAuthor} says..." else @title
    $("title").html(newTitle)
    @showingTitle = not @showingTitle

  onNewMessage: (event, messageObject) =>
    bottom = Util.scrolledToBottom()
    messagePartial = @renderMessagePartial(messageObject)
    if messageObject.channel isnt @channelViewCollection.currentChannel
      @channelViewCollection.highlightChannel(messageObject.channel)
    @checkAndNotify(messagePartial, messageObject.user.name)
    $message = @appendMessage(messageObject, messagePartial)
    return unless $message?
    if bottom
      @scrollToBottom(animate: true)
      $message.find("img").one("load", => @scrollToBottom(animate: true))
    else
      @notifier.activate()

  onPreviewMessage: (event, messageObject) =>
    messagePreviewDiv = $("#message-preview .message")
    $messageContainer = $(Mustache.render(@messagePartialTemplate, messageObject))
    messagePreviewDiv.replaceWith($messageContainer)
    $("#message-preview").modal("show")

  appendInitialMessages: =>
    target = $(".chat-column")[0]
    spinner = new Spinner(Util.spinConfig).spin(target)
    $.ajax
      url: "/api/messages"
      dataType: "JSON"
      success: (messageHash) =>
        for channel, messages of messageHash
          @appendMessages(messages, quiet: true)
        @messageHub.unblockDequeue()
        @scrollToBottom(animate: false)
        spinner.stop()
        $("#spin-overlay").fadeOut(200)
        $("#chat-text").focus()

  appendMessages: (messages, options) =>
    for message in messages
      if options.quiet
        messagePartial = @renderMessagePartial(message)
        @appendMessage(message, messagePartial)
      else
        @onNewMessage("publish_message", message)

  # following three functions are helpers for @appendMessage
  findMessageEmail: (message) -> message.find(".email").text()
  findMessageTime: (message) -> parseInt(message.find(".time").attr("data-time"))
  newMessageInTimeWindow: (recentMessage, oldMessage) =>
    # recentMessage: a javascript object (received from the server socket connection)
    # oldMessage: a JQuery object (from the DOM)
    (recentMessage["datetime"] - @findMessageTime(oldMessage)) <= @collapseTimeWindow

  renderMessagePartial: (message) =>
    mustached = $(Mustache.render(@messagePartialTemplate, message))
    mustached.find(".user-mention[data-username='#{@username}']").addClass("its-you")
    mustached.find(".channel-mention").on("click", @channelViewCollection.joinChannelClick)
    mustached

  appendMessage: (message, messagePartial) =>
    return if $("#" + message.message_id).length > 0

    if message.datetime >= @latestMessage.datetime
      @latestMessage = message

    messagesList = @channelHash[message.channel].$el
    lastMessage = messagesList.find(".message-container").last()

    # if the author of consecutive messages are the same, collapse them
    if @findMessageEmail(lastMessage) is message.user.email and @newMessageInTimeWindow(message, lastMessage)
      messagePartial.appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", message["datetime"])
      @dateTimeHelper.removeBindings(timeContainer)
    else
      $messageContainer = $(Mustache.render(@messageContainerTemplate, message))
      $messageContainer.filter(".message-container").append(messagePartial)
      $messageContainer.appendTo(messagesList)
      timeContainer = $messageContainer.find(".time")
    @dateTimeHelper.bindOne(timeContainer)
    @dateTimeHelper.updateTimestamp(timeContainer)
    messagePartial

  pullMissingMessages: =>
    id = @latestMessage.message_id or "none"
    $.ajax
      url: "/api/messages_since/#{id}"
      dataType: "json"
      success: (messages) =>
        @appendMessages(messages, quiet: false)
      error: (xhr, textStatus, errorThrown) =>
        console.log "Error updating messages: #{textStatus}, #{errorThrown}"
      complete:
        @messageHub.unblockDequeue()
