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
    $(".chat-edit").click(@onEditSubmit)
    @previewVisible = false
    @currentMessage = ""
    @chatHistoryOffset = -1

  onPreviewSubmit: (event) =>
    message = @chatText.val()
    @messageHub.sendPreview(message, @channelViewCollection.currentChannel)
    $(".preview-wrapper").show()
    $(".chat-preview").hide()
    $(".chat-edit").show()
    $(".chat-text-wrapper").hide()
    @previewVisible = true

  onEditSubmit: (event) =>
    $(".preview-wrapper").hide()
    $(".chat-preview").show()
    $(".chat-edit").hide()
    $(".chat-text-wrapper").show()
    @chatText.focus()
    @previewVisible = false

  onChatSubmit: (event) =>
    message = @chatText.val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendChat(message, @channelViewCollection.currentChannel)
      @onEditSubmit() if @previewVisible
      @addToChatHistory(message)
    @chatText.val("").focus()
    event.preventDefault()

  onExpandRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-icon").html("right")
    $(".right-sidebar").removeClass("closed")
    $(".chat-column").removeClass("collapse-right")
    rightSidebarButton.one("click", @onCollapseRightSidebar)
    document.cookie = "rightSidebar=open"

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-icon").html("left")
    $(".right-sidebar").addClass("closed")
    $(".chat-column").addClass("collapse-right")
    rightSidebarButton.one("click", @onExpandRightSidebar)
    document.cookie = "rightSidebar=closed"

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-icon").html("left")
    $(".left-sidebar").removeClass("closed")
    $(".main-content").removeClass("collapse-left")
    leftSidebarButton.one("click", @onCollapseLeftSidebar)
    document.cookie = "leftSidebar=open"

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-icon").html("right")
    $(".left-sidebar").addClass("closed")
    $(".main-content").addClass("collapse-left")
    leftSidebarButton.one("click", @onExpandLeftSidebar)
    document.cookie = "leftSidebar=closed"

  onNextChatHistory: =>
    if @chatText.caret() == @chatText.val().length
      history = JSON.parse(localStorage.getItem("chat_history"))
      if history != null && history.length > 0
        if @chatHistoryOffset == -1
          @chatText.val(@currentMessage)
        else
          @chatHistoryOffset = @chatHistoryOffset - 1
          if @chatHistoryOffset == -1
            @chatText.val(@currentMessage)
          else
            @chatText.val(history[history.length-@chatHistoryOffset-1])

  onPreviousChatHistory: =>
    if @chatText.caret() == 0
      if @chatHistoryOffset == -1
        @currentMessage = @chatText.val()
      history = JSON.parse(localStorage.getItem("chat_history"))
      if history!= null && history.length > 0
        if @chatHistoryOffset == history.length-1
          @chatText.val(history[0])
        else
          @chatHistoryOffset = @chatHistoryOffset + 1
          @chatText.val(history[history.length-@chatHistoryOffset-1])

  addToChatHistory: (message) =>
    history = JSON.parse(localStorage.getItem("chat_history"))
    if history == null
      history = new Array()
    history.push(message)
    while history.length > 50
      history.shift()
      
    localStorage.setItem("chat_history", JSON.stringify(history))
    @chatHistoryOffset = -1
    @currentMessage = ""

