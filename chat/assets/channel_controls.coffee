class window.ChannelView extends Backbone.View
  _.extend @::, Backbone.Events

  tagName: "div"
  className: "channel-button-container"

  initialize: (options) =>
    @name = options.name
    @template = $("#channel-button-template").html()
    @render()
    @channelButton = @$el.find(".channel")

  render: =>
    @$el.html(Mustache.render(@template, name: @name))
    @$el.find(".leave").click(=> @trigger("leaveChannel", @name))
    @$el.hover((=> @$el.addClass("hover")), => @$el.removeClass("hover"))

  onClick: =>
    $(".chat-controls .channel-name").html(@name)
    @channelButton.removeClass("unread")
    @channelButton.addClass("current").off("mouseup")
    @trigger("changeCurrentChannel", @name)

  setInactive: =>
    @channelButton.removeClass("current").mouseup(@onClick)

  highlight: =>
    @channelButton.addClass("unread")


class window.ChannelViewCollection extends Backbone.View
  tagName: "div"
  className: "channel-list-container"

  initialize: (options) =>
    @channelsHash = {}
    @currentChannel = options.currentChannel
    @messageHub = options.messageHub
    @channels = options.channels

    for channel in options.channels
      @channelsHash[channel] = new ChannelView(name: channel)
    $(".channel-controls-container").prepend(@$el)

    $('.add-channel-container').one("click", @showNewChannel)
    $('.new-channel-name').click((event) -> event.stopPropagation())
    $(".new-channel-name").on("keydown.return", @onSubmitChannel)
    @render()

  onSubmitChannel: (event) =>
    newChannel = event.target.value
    if newChannel.replace(/\s*$/, "") isnt ""
      @joinChannel(newChannel)
    @hideNewChannel(animate: false)

  render: =>
    @$el.children().detach()
    @addNewChannelView(@channelsHash[channel]) for channel in @channels

  onChannelChange: (nextCurrentChannel) =>
    @channelsHash[@currentChannel]?.setInactive()
    @currentChannel = nextCurrentChannel
    @trigger("changeCurrentChannel", nextCurrentChannel)
    @messageHub.switchChannel(@currentChannel)

  showNewChannel: =>
    $(".add-channel-container").stop(true)
                               .animate(width: "133px", 500, -> $('.new-channel-name').show())
                               .one("click", => @hideNewChannel())

  hideNewChannel: (options={ animate: true }) =>
    newChannelName = $('.new-channel-name')
    newChannelName.val('')
    newChannelName.hide()
    newChannelUI = $(".add-channel-container")
    if options.animate
      newChannelUI.stop(true)
                  .animate(width: "15px", 500, -> newChannelName.hide())
    else
      newChannelName.hide()
      newChannelUI.width(15)
    newChannelUI.one("click", @showNewChannel)

  highlightChannel: (channel) ->
    @channelsHash[channel].highlight()

  leaveChannel: (channel) =>
    @channels = _.without(@channels, channel)
    @channelsHash[channel].$el.remove()
    delete @channelsHash[channel]
    Util.cleanupTipsy()
    @messageHub.leaveChannel(channel)
    @trigger("leaveChannel", channel)
    $("button.channel").first().mouseup() if channel is @currentChannel and @channels.length > 0

  addNewChannelView: (view) =>
    if view.name isnt @currentChannel
      view.setInactive()
    else
      view.channelButton.addClass("current")
    view.on("changeCurrentChannel", @onChannelChange)
    view.on("leaveChannel", @leaveChannel)
    @$el.append(view.$el)


  joinChannel: (channel) =>
    return if _.include(@channels, channel)
    @channels.push(channel)
    view = @channelsHash[channel] = new ChannelView(name: channel)
    @addNewChannelView(view)
    @trigger("joinChannel", channel)
    @messageHub.joinChannel(channel)
