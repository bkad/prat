dependencies = [
  "ngCookies"
  "ngRoute"
  "ngSanitize"
  "ui.bootstrap"
  "ui.keypress"
  "ui.router"
  "ui.sortable"
  "prat.services"
  "pasvaz.bindonce"
]



module = angular.module "prat", dependencies

module.config ($routeProvider, $tooltipProvider) ->
  $routeProvider.when "/",
    templateUrl: "main-template"
    controller: "mainCtrl"
    controllerAs: "main"

  $tooltipProvider.options
    placement: "top"
    animation: "true"
    popupDelay: 0
    appendToBody: true

module.controller "mainCtrl", ($scope, $http, $cookieStore, eventHub) ->
  $scope.leftSidebarClosed = $cookieStore.get("leftSidebarClosed") ? false
  $scope.rightSidebarClosed = $cookieStore.get("rightSidebarClosed") ? false
  $scope.activeChannel = INITIAL.lastSelectedChannel
  $scope.channelOrder = INITIAL.channels
  collapseTimeWindow = INITIAL.collapseTimeWindow

  $scope.preferences =
    hideOffline = false
  $scope.channels = {}
  for channel in $scope.channelOrder
    $scope.channels[channel] =
      messageGroups: []

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
    eventHub.sendJSON
      action: "switch_channel"
      data:
        channel: channel

  appendMessage = (channel, message) ->
    messageGroups = $scope.channels[channel].messageGroups
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

  fetchInitialStatuses = ->
    $http
      url: "/api/user_status"
      method: "GET"
    .success (data, status, headers, config) ->
      for channel, users of data
        $scope.channels[channel].users = users
    .error (data, status, headers, config) ->
      console.log "Error updating channels: #{status}, #{data}"

  $scope.userSort = [
    "-isCurrentUser"
    (user) -> user.status isnt "active"
    "name"
  ]

  $scope.channelSortable =
    placeholder: "channel-button-placeholder"
    handle: ".reorder"
    axis: "y"
    stop: (e, ui) ->
      eventHub.sendJSON
        action: "reorder_channels"
        data:
          channels: $scope.channelOrder

  fetchInitialMessages()
  fetchInitialStatuses()
