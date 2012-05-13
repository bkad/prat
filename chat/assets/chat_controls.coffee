class window.ChatControls
  constructor: ->

  init: (leftSidebarClosed, rightSidebarClosed) ->
    rightToggle = if rightSidebarClosed then @onExpandRightSidebar else @onCollapseRightSidebar
    leftToggle = if leftSidebarClosed then @onExpandLeftSidebar else @onCollapseLeftSidebar
    $(".toggle-right-sidebar").click(rightToggle)
    $(".toggle-left-sidebar").click(leftToggle)

  onExpandRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.unbind("click")
    rightSidebarButton.html("⇥")
    $(".right-sidebar").css("display", "block")
    $(".chat-column").css("right", "200px")
    rightSidebarButton.click(@onCollapseRightSidebar)
    document.cookie = "rightSidebar=open"

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.unbind("click")
    rightSidebarButton.html("⇤")
    $(".right-sidebar").css("display", "none")
    $(".chat-column").css("right", "0px")
    rightSidebarButton.click(@onExpandRightSidebar)
    document.cookie = "rightSidebar=closed"

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇤")
    $(".left-sidebar").css("display", "block")
    $(".main-content").css("left", "200px")
    leftSidebarButton.click(@onCollapseLeftSidebar)
    document.cookie = "leftSidebar=open"

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇥")
    $(".left-sidebar").css("display", "none")
    $(".main-content").css("left", "0px")
    leftSidebarButton.click(@onExpandLeftSidebar)
    document.cookie = "leftSidebar=closed"
