class window.ChatControls
  constructor: (@messageHub, @channelViewCollection, leftClosed, rightClosed) ->
    @init(leftClosed, rightClosed)

  init: (leftSidebarClosed, rightSidebarClosed) ->
    rightToggle = if rightSidebarClosed then @onExpandRightSidebar else @onCollapseRightSidebar
    leftToggle = if leftSidebarClosed then @onExpandLeftSidebar else @onCollapseLeftSidebar
    $(".toggle-right-sidebar").one("click", rightToggle)
    $(".toggle-left-sidebar").one("click", leftToggle)
    @chatText = $("#chat-text")
    @chatText.on("keydown.return", @onChatSubmit)
    @chatText.on("keydown.up", @onPreviousChatHistory)
    @chatText.on("keydown.down", @onNextChatHistory)
    @messageHub.on("force_refresh", @refreshPage)
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-preview").click(@onPreviewSubmit)
    $("#preview-submit").click(@onPreviewSend)
    @currentMessage = ""
    @chatHistoryOffset = -1

  onPreviewSubmit: (event) =>
    message = @chatText.val()
    @messageHub.sendPreview(message, @channelViewCollection.currentChannel)

  onChatSubmit: (event) =>
    message = @chatText.val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendChat(message, @channelViewCollection.currentChannel)
      @addToChatHistory(message)
    @chatText.val("").focus()
    event.preventDefault()

  onPreviewSend: =>
    $("#message-preview").modal("hide")
    @onChatSubmit(preventDefault: ->)

  onExpandRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-standard").html("right")
    $(".right-sidebar").removeClass("closed")
    $(".chat-column").removeClass("collapse-right")
    rightSidebarButton.one("click", @onCollapseRightSidebar)
    document.cookie = "rightSidebar=open"

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-standard").html("left")
    $(".right-sidebar").addClass("closed")
    $(".chat-column").addClass("collapse-right")
    rightSidebarButton.one("click", @onExpandRightSidebar)
    document.cookie = "rightSidebar=closed"

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-standard").html("left")
    $(".left-sidebar").removeClass("closed")
    $(".main-content").removeClass("collapse-left")
    leftSidebarButton.one("click", @onCollapseLeftSidebar)
    document.cookie = "leftSidebar=open"

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-standard").html("right")
    $(".left-sidebar").addClass("closed")
    $(".main-content").addClass("collapse-left")
    leftSidebarButton.one("click", @onExpandLeftSidebar)
    document.cookie = "leftSidebar=closed"

  getChatHistory: ->
    JSON.parse(localStorage.getItem("chat_history"))

  setChatHistory: (history) ->
    localStorage.setItem("chat_history", JSON.stringify(history))

  getChatFromHistory: (history) ->
    history[history.length - @chatHistoryOffset - 1]

  onNextChatHistory: =>
    return unless @chatText.caret() is @chatText.val().length
    history = @getChatHistory()
    return unless history?.length > 0 and @chatHistoryOffset isnt -1
    @chatHistoryOffset--
    newValue = if @chatHistoryOffset is -1 then @currentMessage else @getChatFromHistory(history)
    @chatText.val(newValue)

  onPreviousChatHistory: =>
    return unless @chatText.caret() is 0
    if @chatHistoryOffset is -1
      @currentMessage = @chatText.val()
    history = @getChatHistory()
    return unless history?.length > 0
    if @chatHistoryOffset is history.length-1
      @chatText.val(history[0])
    else
      @chatHistoryOffset++
      @chatText.val(@getChatFromHistory(history))

  addToChatHistory: (message) =>
    history = @getChatHistory()
    history ?= []
    history.push(message)
    history.shift() while history.length > 50
      
    @setChatHistory(history)
    @chatHistoryOffset = -1
    @currentMessage = ""

