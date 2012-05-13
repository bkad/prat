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
    $(".right-sidebar").removeClass("closed")
    $(".chat-column").removeClass("collapse-right")
    rightSidebarButton.click(@onCollapseRightSidebar)
    document.cookie = "rightSidebar=open"

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.unbind("click")
    rightSidebarButton.html("⇤")
    $(".right-sidebar").addClass("closed")
    $(".chat-column").addClass("collapse-right")
    rightSidebarButton.click(@onExpandRightSidebar)
    document.cookie = "rightSidebar=closed"

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇤")
    $(".left-sidebar").removeClass("closed")
    $(".main-content").removeClass("collapse-left")
    leftSidebarButton.click(@onCollapseLeftSidebar)
    document.cookie = "leftSidebar=open"

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.unbind("click")
    leftSidebarButton.html("⇥")
    $(".left-sidebar").addClass("closed")
    $(".main-content").addClass("collapse-left")
    leftSidebarButton.click(@onExpandLeftSidebar)
    document.cookie = "leftSidebar=closed"
