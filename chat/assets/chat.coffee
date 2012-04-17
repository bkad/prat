class window.Chat
  constructor: (@address) ->
    $(".chat-submit").click(@onChatSubmit)
    @socket = new WebSocket(@address)
    @socket.onmessage = @onEvent
    $(".toggle-right-sidebar").click(@onCollapseRightSidebar)
    $(".toggle-left-sidebar").click(@onCollapseLeftSidebar)

  onChatSubmit: =>
    message = $(".chat-text").val()
    @socket.send(message)
    $(".chat-text").val("")

  onEvent: (jsonMessage) =>
    messageObject = JSON.parse(jsonMessage.data)
    newMessage = "<div class=\"message\">" +
      "<div class=\"message-author\">#{messageObject["author"]}</div>" +
      "<div class=\"message-contents\">#{messageObject["message"]}</div>" +
      "</div>"
      $(".chat-messages-container").append(newMessage)

  onExpandRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.unbind("click")
    rightSidebarButton.html("⇥")
    $(".right-sidebar").css("display", "block")
    $(".chat-column").css("right", "200px")
    rightSidebarButton.click(@onCollapseRightSidebar)

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.unbind("click")
    rightSidebarButton.html("⇤")
    $(".right-sidebar").css("display", "none")
    $(".chat-column").css("right", "0px")
    rightSidebarButton.click(@onExpandRightSidebar)

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇤")
    $(".left-sidebar").css("display", "block")
    $(".main-content").css("left", "200px")
    leftSidebarButton.click(@onCollapseLeftSidebar)

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇥")
    $(".left-sidebar").css("display", "none")
    $(".main-content").css("left", "0px")
    leftSidebarButton.click(@onExpandLeftSidebar)
