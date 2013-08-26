$ ->
  window.CurrentUserEmail = Initial.email
  window.CurrentChannel = Initial.last_selected_channel
  window.DefaultTooltip = animation: false, container: "body"

  window.Channels = new ChannelViewCollection(channels: Initial.channels)
  Users.init(Initial.channels)

  ChatControls.init
    leftSidebarClosed: Initial.left_sidebar_closed
    rightSidebarClosed: Initial.right_sidebar_closed

  ImgurUploader.init(Initial.imgur_client_id, new AlertHelper())

  UserGuide.init()
  Preferences.init(Initial.preferences)
  sound = new Sound("/static/audio/ping.mp3")

  dateTimeHelper = new DateTimeHelper()

  messagesViewCollection = new MessagesViewCollection
    sound: sound
    channels: Initial.channels
    username: Initial.username
    dateTimeHelper: dateTimeHelper
    collapseTimeWindow: Initial.collapse_time_window
    title: Initial.name


  websocketProtocol = if "https:" is document.location.protocol then "wss" else "ws"
  MessageHub.init("#{websocketProtocol}://#{document.location.host}/eventhub",
                  4000,
                  Initial.websocket_keep_alive_interval,
                  new AlertHelper())

  MessageHub.deferDequeue(messagesViewCollection.appendInitialMessages, Users.updateAllChannels)

  for btn in ["logout", "user-info-button", "settings-button"]
    $("##{btn}").tooltip(DefaultTooltip)
