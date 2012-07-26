class window.Chat
  constructor: (@messageHub, @collapseTimeWindow, @channelControls, @dateTimeHelper) ->

  init: ->
    @messageContainerTemplate = $("#message-container-template").html()
    @messagePartialTemplate = $("#message-partial-template").html()
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-text").on("keydown.return", @onChatSubmit)
    @messageHub.subscribe("message", @onNewMessage)

  onChatSubmit: (event) =>
    message = $(".chat-text").val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendChat(message, @channelControls.currentChannel)
    $(".chat-text").val("").focus()
    event.preventDefault()

  onNewMessage: (messageObject) =>
    bottom = Util.scrolledToBottom()
    @appendMessage(messageObject.data) if messageObject.action is "message"
    Util.scrollToBottom("animate") if bottom

  appendInitialMessages: (messageDict) =>
    for channel, messages of messageDict
      for message in messages
        @appendMessage(message)

  # following three functions are helpers for @appendMessage
  findMessageEmail: (message) -> message.find(".email").text()
  findMessageTime: (message) -> parseInt(message.find(".time").attr("data-time"))
  newMessageInTimeWindow: (recentMessage, oldMessage) =>
    # recentMessage: a javascript object (received from the server socket connection)
    # oldMessage: a JQuery object (from the DOM)
    (recentMessage["datetime"] - @findMessageTime(oldMessage)) <= @collapseTimeWindow

  appendMessage: (message) =>
    messagesList = $(".chat-messages-container[data-channel='#{message["channel"]}']")
    lastMessage = messagesList.find(".message-container").last()
    $message = $(Mustache.render(@messagePartialTemplate, message))

    # if the author of consecutive messages are the same, collapse them
    if @findMessageEmail(lastMessage) is message["email"] and @newMessageInTimeWindow(message, lastMessage)
      $message.appendTo(lastMessage)
      # remove the old time data binding and refresh the time attribute
      timeContainer = lastMessage.find(".time")
      timeContainer.attr("data-time", message["datetime"])
      @dateTimeHelper.removeBindings(timeContainer)
    else
      $messageContainer = $(Mustache.render(@messageContainerTemplate, message))
      $messageContainer.filter(".message-container").append($message)
      $messageContainer.appendTo(messagesList)
      timeContainer = $messageContainer.find(".time")
    @dateTimeHelper.bindOne(timeContainer)
    @dateTimeHelper.updateTimestamp(timeContainer)
