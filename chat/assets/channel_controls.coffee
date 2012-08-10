class window.ChannelView extends Backbone.View
  _.extend @::, Backbone.Events

  tagName: "button"
  className: "channel"

  initialize: (options) =>
    @name = options.name
    @render()

  render: =>
    @$el.html(@name)

  onClick: =>
    $(".chat-controls .channel-name").html(@name)
    @$el.addClass("current").off("mouseup")
    @trigger("changeCurrentChannel", @name)

  setInactive: =>
    @$el.removeClass("current").mouseup(@onClick)


class window.ChannelViewCollection extends Backbone.View
  tagName: "div"
  className: "channel-list-container"

  initialize: (options) =>
    @channelsHash = {}
    @currentChannel = options.currentChannel
    @channelUsers = options.channelUsers
    @messageHub = options.messageHub
    @channels = options.channels

    for channel in options.channels
      @channelsHash[channel] = new ChannelView(name: channel)
    $(".channel-controls-container").prepend(@$el)

    $('.add-channel-container').toggle(
      ((event) -> $('.add-channel-container').stop(true).animate(width: "133px", 500, ->
        $('.new-channel-name').show())),
      @hideNewChannel)
    $('.new-channel-name').click((event) -> event.stopPropagation())
    @render()

  render: =>
    @$el.children().detach()
    for channel in @channels
      view = @channelsHash[channel]
      if channel isnt @currentChannel
        view.setInactive()
      else
        view.$el.addClass("current")

      view.on("changeCurrentChannel", @onChannelChange)
      @$el.append(view.$el)

  onChannelChange: (nextCurrentChannel) =>
    @channelsHash[@currentChannel].setInactive()
    @currentChannel = nextCurrentChannel
    @trigger("changeCurrentChannel", nextCurrentChannel)
    @channelUsers.displayUserStatuses(@currentChannel)
    @messageHub.switchChannel(@currentChannel)

  hideNewChannel: (event) ->
    newChannelName = $('.new-channel-name')
    newChannelName.val('')
    newChannelName.hide()
    $('.add-channel-container').stop(true).animate(width: "15px", 500, -> newChannelName.hide())
