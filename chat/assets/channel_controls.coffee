class window.ChannelControls
  constructor: (@currentChannel, @messageHub, @channelUsers) ->
    @init()

  init: =>
    $(".channel:not(.active)").mouseup(@onSelectActiveChannel)
    $('.add-channel-container').toggle(
      ((event) -> $('.add-channel-container').stop(true).animate({ width: '133px' }, 500, ->
        $('.new-channel-name').show())),
      @hideNewChannel)
    $('.new-channel-name').click((event) -> event.stopPropagation())

  onSelectActiveChannel: (event) =>
    target = $(event.target)
    @currentChannel = target.data("channel-name")
    $(".chat-controls .channel-name").html(@currentChannel)
    $(".channel.current").removeClass("current").mouseup(@onSelectActiveChannel)
    $(".chat-messages-container.current").removeClass("current")
    target.addClass("current").off("mouseup")
    $(".chat-messages-container[data-channel='#{@currentChannel}']").addClass("current")
    @channelUsers.displayUserStatuses(@currentChannel)
    @messageHub.switchChannel(@currentChannel)
    Util.scrollToBottom("noAnimate")

  hideNewChannel: (event) ->
    newChannelName = $('.new-channel-name')
    newChannelName.val('')
    newChannelName.hide()
    $('.add-channel-container').stop(true).animate({ width: '15px' }, 500, -> newChannelName.hide())
