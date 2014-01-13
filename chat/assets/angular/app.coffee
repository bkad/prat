module = angular.module "prat", ["ngRoute", "ui.keypress", "prat.services"]

module.config ($routeProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "mainCtrl"
    controllerAs: "main"

module.controller "mainCtrl", ($scope, eventHub) ->
  $scope.leftSidebarClosed = INITIAL.leftSidebarClosed
  $scope.rightSidebarClosed = INITIAL.rightSidebarClosed
  $scope.activeChannel = "general"
  $scope.channels = ["general"]
  $scope.channelMap =
    general:
      name: "general"
      messageGroups: []

  $scope.messageGroups = []

  $scope.toggleSidebar = (direction) ->
    if direction not in ["left", "right"]
      console.log "ERROR: toggleSidebar only accepts 'left' or 'right'"
      return
    $scope["#{direction}SidebarClosed"] = not $scope["#{direction}SidebarClosed"]

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
