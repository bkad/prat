dependencies = [
  "ngCookies"
  "ngRoute"
  "ngSanitize"
  "ui.bootstrap"
  "ui.keypress"
  "ui.router"
  "prat.services"
  "pasvaz.bindonce"
]



module = angular.module "prat", dependencies

module.config ($routeProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "mainCtrl"
    controllerAs: "main"

module.controller "mainCtrl", ($scope, $http, $cookieStore, eventHub) ->
  $scope.leftSidebarClosed = $cookieStore.get("leftSidebarClosed") ? false
  $scope.rightSidebarClosed = $cookieStore.get("rightSidebarClosed") ? false
  $scope.activeChannel = INITIAL.lastSelectedChannel
  $scope.channels = INITIAL.channels
  collapseTimeWindow = INITIAL.collapseTimeWindow

  $scope.channelMap = {}
  for channel in $scope.channels
    $scope.channelMap[channel] = []

  $scope.toggleSidebar = (direction) ->
    if direction not in ["left", "right"]
      console.log "ERROR: toggleSidebar only accepts 'left' or 'right'"
      return
    property = "#{direction}SidebarClosed"
    closed = not $scope[property]
    $cookieStore.put(property, closed)
    $scope[property] = closed

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

  appendMessage = (channel, message) ->
    messageGroups = $scope.channelMap[channel]
    if messageGroups.length is 0 or ((message.datetime - messageGroups[messageGroups.length - 1].datetime) > collapseTimeWindow)
      messageGroups.push
        datetime: message.datetime
        user: message.user
        messages: [message]
    else
      lastGroup = messageGroups[messageGroups.length - 1]
      lastGroup.datetime = message.datetime
      lastGroup.messages.push(message)

  fetchInitialMessages = ->
    $http
      url: "/api/messages"
      method: "GET"
    .success (data, status, headers, config) ->
      for channel, messages of data
        appendMessage(channel, message) for message in messages

  fetchInitialMessages()
