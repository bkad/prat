class MessageView extends Backbone.View
  className: "message-container"
  tagName: "div"
  initialize: (options) ->
    @datetime = options.datetime
    @collapseTime = options.collapseTime
  
angular.module "prat.directives"
.directive "messages", (eventHub, config, humanDate) ->
  restrict: "E"
  template: ""
  scope:
    channel: "="
  link: (scope, element, attrs) ->
    messageView = new MessageView
      collapseTime: config.collapseTimeWindow
      datetime: humanDate

    #lastGroup =
    onNewMessage = (eventType, payload) ->
      return unless payload.channel is scope.channel
      messageView.append(payload)

    eventHub.on("publish_message", onNewMessage)
