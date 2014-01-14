module = angular.module "prat", ["ngRoute", "ui.keypress", "ui.bootstrap", "prat.services"]

module.config ($routeProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "mainCtrl"
    controllerAs: "main"

module.controller "mainCtrl", ($scope, eventHub) ->
  $scope.leftSidebarClosed = INITIAL.leftSidebarClosed
  $scope.rightSidebarClosed = INITIAL.rightSidebarClosed
  $scope.activeChannel = INITIAL.lastSelectedChannel
  $scope.channels = INITIAL.channels

  $scope.channelMap = {}
  for channel in $scope.channels
    $scope.channelMap[channel] =
      name: channel
      messageGroups: []

  $scope.messageGroups = []

  $scope.toggleSidebar = (direction) ->
    if direction not in ["left", "right"]
      console.log "ERROR: toggleSidebar only accepts 'left' or 'right'"
      return
    closed = not $scope["#{direction}SidebarClosed"]
    document.cookie = "#{direction}Sidebar=#{if closed then "closed" else "open"}"
    $scope["#{direction}SidebarClosed"] = closed

  $scope.sendMessage = (input, channel, event) ->
    if input.message?.replace(/\s*$/, "") isnt ""
      console.log "#{channel}: #{input.message}"
      #eventHub.sendJSON
        #action: "publish_message"
        #data:
          #message: message
          #channel: "general"
      input.message = ""
      event?.preventDefault()

  $scope.switchChannel = (channel) ->
    $scope.activeChannel = channel
