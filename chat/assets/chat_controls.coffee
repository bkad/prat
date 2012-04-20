class window.ChatControls
  constructor: ->
    $(".toggle-right-sidebar").click(@onCollapseRightSidebar)
    $(".toggle-left-sidebar").click(@onCollapseLeftSidebar)

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
