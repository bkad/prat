class window.ChannelView extends Backbone.View
  tagName: "div"
  className: "channel-button-container"

  initialize: (options) =>
    @name = options.name
    @template = $("#channel-button-template").html()
    @render()
    @channelButton = @$(".channel")

  render: =>
    @$el.html(Util.mustache(@template, name: @name))
    @$(".leave").tooltip(DefaultTooltip)
      .click(=> @trigger("leaveChannel", @name))
    @$el.hover((=> @$el.addClass("hover")), => @$el.removeClass("hover"))

  onClick: =>
    $(".chat-controls .channel-name").html(@name)
    @channelButton.removeClass("unread")
    @channelButton.addClass("current").off("click")
    @trigger("changeCurrentChannel", @name)

  setInactive: =>
    @channelButton.removeClass("current").click(@onClick)

  highlight: =>
    @channelButton.addClass("unread")


class window.ChannelViewCollection extends Backbone.View
  tagName: "div"
  className: "channel-list-container"

  initialize: (options) =>
    @channelsHash = {}
    @channels = options.channels

    for channel in options.channels
      @channelsHash[channel] = new ChannelView(name: channel)
    $(".channel-controls-container").prepend(@$el)
    @$el.disableSelection()

    @newChannelState = "hidden"
    $(".add-channel-container").click(@toggleNewChannel)
    $(".new-channel-name").click((e) -> e.stopPropagation())
      .on("keydown.esc", => @hideNewChannel())
      .on("keydown.return", @onSubmitChannel)
      .on("blur", => @hideNewChannel() if @newChannelState is "shown")
    @render()

  onSubmitChannel: (event) =>
    newChannel = event.target.value
    $(".new-channel-name").val("")
    if newChannel.replace(/\s*$/, "") isnt ""
      @joinChannel(newChannel)
      @channelsHash[newChannel].onClick()
    @hideNewChannel(animate: false)

  render: =>
    @$el.children().detach()
    @addNewChannelView(@channelsHash[channel]) for channel in @channels
    @$el.sortable
      placeholder: "channel-button-placeholder"
      handle: ".reorder"
      axis: "y"
      update: @updateChannelOrder

  updateChannelOrder: =>
    @channels = new Array(@channels.length)
    newDom = @$el.children()
    for channel, view of @channelsHash
      @channels[newDom.index(view.el)] = channel
    MessageHub.reorderChannels(@channels)

  onChannelChange: (nextCurrentChannel) =>
    return if nextCurrentChannel is CurrentChannel
    @channelsHash[CurrentChannel]?.setInactive()
    window.CurrentChannel = nextCurrentChannel
    @trigger("changeCurrentChannel", nextCurrentChannel)
    MessageHub.switchChannel(CurrentChannel)

  toggleNewChannel: =>
    switch @newChannelState
      when "hidden" then @showNewChannel()
      when "shown" then @hideNewChannel()

  showNewChannel: =>
    @newChannelState = "between"
    $(".plus-label").removeClass("unrotated")
    $(".plus-label").addClass("rotated")
    $(".add-channel-container")
      .stop(true)
      .animate(width: "133px", 150, =>
        channelName = $(".new-channel-name")
        channelName.show()
        channelName.focus()
        @newChannelState = "shown"
      )

  hideNewChannel: (options = animate: true) =>
    @newChannelState = "between"
    newChannelName = $('.new-channel-name')
    newChannelName.blur()
    newChannelName.hide()
    newChannelUI = $(".add-channel-container")
    $(".plus-label").addClass("unrotated")
    $(".plus-label").removeClass("rotated")
    if options.animate
      newChannelUI.stop(true)
        .animate(width: "15px", 150, =>
          newChannelName.hide()
          @newChannelState = "hidden"
        )
    else
      newChannelName.hide()
      newChannelUI.width(15)
      @newChannelState = "hidden"

  highlightChannel: (channel) ->
    @channelsHash[channel].highlight()

  leaveChannel: (channel) =>
    @channels = _.without(@channels, channel)
    @channelsHash[channel].$el.remove()
    delete @channelsHash[channel]
    Util.cleanupTooltips()
    MessageHub.leaveChannel(channel)
    @trigger("leaveChannel", channel)
    $("button.channel").first().click() if channel is CurrentChannel and @channels.length > 0

  addNewChannelView: (view) =>
    if view.name isnt CurrentChannel
      view.setInactive()
    else
      view.channelButton.addClass("current")
    view.on("changeCurrentChannel", @onChannelChange)
    view.on("leaveChannel", @leaveChannel)
    @$el.append(view.$el)

  joinChannel: (channel) =>
    if channel not in @channels
      @channels.push(channel)
      view = @channelsHash[channel] = new ChannelView(name: channel)
      @addNewChannelView(view)
      @trigger("joinChannel", channel)
      MessageHub.joinChannel(channel)
    return @channelsHash[channel]

  joinChannelClick: (event) =>
    toAdd = $(event.currentTarget).attr("data-channelname")
    @joinChannel(toAdd).onClick()

  # offset is -1 for previous channel
  cycleChannel: (offset = 1) =>
    currentChannelIndex = @$el.children().index(@channelsHash[CurrentChannel].el)
    len = @channels.length
    # Stupid JS mod for negative numbers
    succIndex = (((currentChannelIndex + offset) % len) + len) % len
    @channelsHash[@channels[succIndex]].onClick()
