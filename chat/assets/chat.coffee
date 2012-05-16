class window.Chat
  constructor: (@address) ->

  init: ->
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-text").on("keyup.ctrl_return", @onChatSubmit)
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent

  sendSwitchChannelEvent: (channel) =>
    @socket.send(JSON.stringify({"action":"switch_channel", "data":{"channel":channel}}))

  onChatSubmit: =>
    message = $(".chat-text").val()
    channel = @channelControls.currentChannel
    @socket.send(JSON.stringify({"action":"publish_message", "data":{"message":message, "channel":channel}}))
    $(".chat-text").val("").focus()

  onEvent: (jsonMessage) =>
    bottom = @scrolledToBottom()
    socketObject = JSON.parse(jsonMessage.data)
    action = socketObject["action"]
    data = socketObject["data"]
    if action == "message"
      message = $(data["message"])
      timeContainer = message.find(".author-container .time")
      dateTimeHelper.bindOne(timeContainer)
      dateTimeHelper.updateTimestamp(timeContainer)
      message.appendTo(".chat-messages-container[data-channel='#{data["channel"]}']")
    @scrollToBottom() if bottom


  scrolledToBottom: ->
    messages = $(".chat-messages-container.current")
    difference = (messages[0].scrollHeight - messages.scrollTop()) is messages.outerHeight()
    return difference <= 1

  scrollToBottom: (animate=true) ->
    messages = $(".chat-messages-container.current")
    method = if animate then "animate" else "prop"
    messages[method](scrollTop: messages[0].scrollHeight)

  setChannelControls: (channelControls) -> @channelControls = channelControls
  setDateTimeHelper: (dateTimeHelper) -> @dateTimeHelper = dateTimeHelper
