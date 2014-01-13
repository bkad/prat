$ ->
  window.CurrentUserEmail = INITIAL.email
  window.CurrentChannel = INITIAL.last_selected_channel
  window.DefaultTooltip = animation: false, container: "body"

  window.Channels = new ChannelViewCollection(channels: INITIAL.channels)
  Users.init(INITIAL.channels)

  ChatControls.init
    leftSidebarClosed: INITIAL.left_sidebar_closed
    rightSidebarClosed: INITIAL.right_sidebar_closed

  ImgurUploader.init(INITIAL.imgur_client_id, new AlertHelper())

  UserGuide.init()
  Preferences.init(INITIAL.preferences)
  sound = new Sound("/static/audio/ping.mp3")

  dateTimeHelper = new DateTimeHelper()

  messagesViewCollection = new MessagesViewCollection
    sound: sound
    channels: INITIAL.channels
    username: INITIAL.username
    dateTimeHelper: dateTimeHelper
    collapseTimeWindow: INITIAL.collapse_time_window
    title: INITIAL.name


  websocketProtocol = if "https:" is document.location.protocol then "wss" else "ws"
  MessageHub.init("#{websocketProtocol}://#{document.location.host}/eventhub",
                  4000,
                  INITIAL.websocket_keep_alive_interval,
                  new AlertHelper())

  MessageHub.deferDequeue(messagesViewCollection.appendInitialMessages, Users.updateAllChannels)

  for btn in ["logout", "user-info-button", "settings-button"]
    $("##{btn}").tooltip(DefaultTooltip)

  window.onbeforeunload = ->
    if $("#chat-text").val().length > 0
      "You have an unsent message."
