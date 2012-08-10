class window.MessagesView extends Backbone.View
  tagName: "div"
  className: "chat-messages"

class window.MessagesViewCollection extends Backbone.View
  tagName: "div"
  className: "chat-messages-container"
  initialize: (options) ->
    @channelHash = {}
    @channels = options.channels
    @collapseTimeWindow = options.collapseTimeWindow
    @dateTimeHelper = options.dateTimeHelper
    @username = options.username
    @sound = options.sound
    $(".input-container").before(@$el)
    options.messageHub.on("publish_message", @onNewMessage)
    options.messageHub.on("preview_message", @onPreviewMessage)
    options.channelViewCollection.on("changeCurrentChannel", @changeCurrentChannel)
    for channel in options.channels
      view = @channelHash[channel] = new MessagesView()
      if channel is channelViewCollection.currentChannel
        view.$el.addClass("current")
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
    @render()

  render: =>
    @$el.children().detach()
    @$el.append(@channelHash[channel].$el) for channel in @channels

  changeCurrentChannel: (newChannel) =>
    view.$el.removeClass("current") for channel, view of @channelHash
    @channelHash[newChannel].$el.addClass("current")
    Util.scrollToBottom("noAnimate")

  checkAndNotify: (message) =>
    if message.find(".its-you").length > 0 and (!document.hasFocus() or document.webkitHidden)
      @sound.playNewMessageAudio()

  onNewMessage: (event, messageObject) =>
    bottom = Util.scrolledToBottom()
    messagePartial = @renderMessagePartial(messageObject)
    @checkAndNotify(messagePartial)
    @appendMessage(messageObject, messagePartial)
    Util.scrollToBottom("animate") if bottom

  onPreviewMessage: (event, messageObject) =>
    messagePreviewDiv = $(".preview-wrapper .message")
    $messageContainer = $(Mustache.render(@messagePartialTemplate, messageObject))
    messagePreviewDiv.replaceWith($messageContainer)

  appendInitialMessages: (messageDict) =>
    for channel, messages of messageDict
      for message in messages
        messagePartial = @renderMessagePartial(message)
        @appendMessage(message, messagePartial)

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
    mustached

  appendMessage: (message, messagePartial) =>
    messagesList = @channelHash[message.channel].$el
    lastMessage = messagesList.find(".message-container").last()

    # if the author of consecutive messages are the same, collapse them
    if @findMessageEmail(lastMessage) is message["email"] and @newMessageInTimeWindow(message, lastMessage)
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
