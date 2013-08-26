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
    @title = options.title
    # latest in terms of date time stamp
    @latestMessage = datetime: 0
    $(".input-container").before(@$el)
    MessageHub.on("publish_message", @onNewMessage)
              .on("preview_message", @onPreviewMessage)
              # We register a special callback for reconnection events because other events defer to it
              .onReconnect(@pullMissingMessages)
    Channels.on("changeCurrentChannel", @changeCurrentChannel)
            .on("leaveChannel", @removeChannel)
            .on("joinChannel", @addChannel)
    for channel in options.channels
      view = @channelHash[channel] = new MessagesView()
      if channel is CurrentChannel
        view.$el.addClass("current")
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
    @render()

  render: =>
    @$el.children().detach()
    @$el.append(@channelHash[channel].el) for channel in @channels

  addChannel: (channel) =>
    @channelHash[channel] = newView = new MessagesView()
    @$el.append(newView.el)
    $.ajax
      url: "/api/messages/#{encodeURIComponent(channel)}"
      dataType: "json"
      success: (messages) =>
        @appendMessages(messages, quiet: true)
        Util.scrollToBottom(animate: false, view: newView.$el)

  removeChannel: (channel) =>
    @channelHash[channel].$el.remove()
    delete @channelHash[channel]

  changeCurrentChannel: (newChannel) =>
    view.$el.removeClass("current") for channel, view of @channelHash
    @channelHash[newChannel].$el.addClass("current")
    Util.scrollToBottom(animate: false)

  checkAndNotify: (message, author) =>
    if !document.hasFocus() or document.webkitHidden
      @lastAuthor = author
      unless @toggleTitleInterval?
        @toggleTitleInterval = setInterval(@toggleTitle, 1500)
      window.onfocus = @clearToggleTitleInterval
      if message.find(".its-you").length > 0 && Preferences.get("alert-sounds")
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
    if messageObject.channel isnt CurrentChannel
      Channels.highlightChannel(messageObject.channel)
    @checkAndNotify(messagePartial, messageObject.user.name)
    $message = @appendMessage(messageObject, messagePartial)
    return unless $message?
    Util.createNotification(null, messageObject.user.name + ' says...', messageObject.message)
    if bottom
      Util.scrollToBottom(animate: true)
      $message.find("img").one("load", -> Util.scrollToBottom(animate: true))

  onPreviewMessage: (event, messageObject) =>
    messagePreviewDiv = $("#message-preview .message")
    $messageContainer = Util.$mustache(@messagePartialTemplate, messageObject)
    $messageContainer.find("img").each((index, elem) => @renderMessageMedia($(elem), true))
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
        Util.scrollToBottom(animate: false)
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
    (recentMessage.datetime - @findMessageTime(oldMessage)) <= @collapseTimeWindow

  renderMessagePartial: (message) =>
    mustached = Util.$mustache(@messagePartialTemplate, message)
    mustached.find(".user-mention[data-username='#{@username}']").addClass("its-you")
    mustached.find(".channel-mention").on("click", Channels.joinChannelClick)

    mustached.find("img").each((index, elem) => @renderMessageMedia($(elem)))

    if Preferences.get("hide-images")
      mustached.find(".image").addClass("closed")
    mustached.find("button.hide-image").on "click", (e) ->
      atBottom = Util.scrolledToBottom()
      $(e.target).parent().toggleClass("closed")
      Util.scrollToBottom() if atBottom
    mustached

  renderMessageMedia: (image, bodyOnly=false) =>
    imageSrc = image.attr("src")
    matches = imageSrc.match(/^.*youtube.com\/watch\?.*v=([^#\&\?]*)/)
    if matches
      embedId = matches[1]
      imageType = "Video"
      imageBody = """
        <iframe type="text/html" width="600" height="400"
                src="http://www.youtube.com/embed/#{embedId}" frameborder="0"/>
        """
    else
      imageType = "Image"
      imageBody = image.get(0).outerHTML
    if bodyOnly
      image.replaceWith -> "#{imageBody}"
    else
      image.replaceWith ->
        """
        <div class='image'>
          <button class='hide-image'></button>
          <span>#{imageType} hidden (<a href='#{@.src}' target='_blank'>link</a>)</span>
          #{imageBody}
        </div>
        """

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
      $messageContainer = Util.$mustache(@messageContainerTemplate, message)
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
