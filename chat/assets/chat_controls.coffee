class window.ChatControls
  constructor: (@messageHub, @channelViewCollection, leftClosed, rightClosed) ->
    @init(leftClosed, rightClosed)

  init: (leftSidebarClosed, rightSidebarClosed) ->
    rightToggle = if rightSidebarClosed then @onExpandRightSidebar else @onCollapseRightSidebar
    leftToggle = if leftSidebarClosed then @onExpandLeftSidebar else @onCollapseLeftSidebar
    $(".toggle-right-sidebar").one("click", rightToggle)
    $(".toggle-left-sidebar").one("click", leftToggle)
    $("#auto-send-toggle").on("mousedown", @onAutoSendToggle)
    $(".chat-text").on("keydown.ctrl_return", @onChatSubmit)
    unless localStorage.autoSend?
      localStorage.autoSend = "true"
    if localStorage.autoSend == "true"
      $(".chat-text").on("keydown.return", @onChatSubmit)
      autoSendSlider = $("#auto-send-container")
      autoSendSlider.removeClass("toggleoff")
      autoSendSlider.addClass("toggleon")
    else
      autoSendSlider = $("#auto-send-container")
      autoSendSlider.removeClass("toggleon")
      autoSendSlider.addClass("toggleoff")
    @messageHub.on("force_refresh", @refreshPage)
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-preview").click(@onPreviewSubmit)
    $(".chat-edit").click(@onEditSubmit)

  onPreviewSubmit: (event) =>
    message = $(".chat-text").val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendPreview(message, @channelViewCollection.currentChannel)

    $(".preview-wrapper").show()
    $(".chat-preview").hide()
    $(".chat-edit").show()
    $(".chat-text-wrapper").hide()

  onEditSubmit: (event) =>
    $(".preview-wrapper").hide()
    $(".chat-preview").show()
    $(".chat-edit").hide()
    $(".chat-text-wrapper").show()

  onChatSubmit: (event) =>
    message = $(".chat-text").val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendChat(message, @channelViewCollection.currentChannel)
    $(".chat-text").val("").focus()
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

  onAutoSendToggle: (event) =>
    autoSendSlider = $("#auto-send-container")
    event.preventDefault()
    if autoSendSlider.hasClass("toggleoff")
      autoSendSlider.removeClass("toggleoff")
      autoSendSlider.addClass("toggleon")
      localStorage.autoSend = "true"
      $(".chat-text").on("keydown.return", @onChatSubmit)
    else
      autoSendSlider.removeClass("toggleon")
      autoSendSlider.addClass("toggleoff")
      localStorage.autoSend = "false"
      $(".chat-text").off("keydown.return", @onChatSubmit)

  refreshPage: ->
    window.location.reload()
