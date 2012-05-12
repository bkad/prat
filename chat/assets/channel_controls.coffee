class window.ChannelControls
  constructor: (@lastSelectedChannel) ->

  init: =>
    $(".channel:not(.active)").mouseup(@onSelectActiveChannel)
    document.location.hash = @lastSelectedChannel
    $('.add-channel-container').toggle(
      ((event) -> $('.add-channel-container').stop(true).animate({ width: '133px' }, 500, ->
        $('.new-channel-name').show())),
      @hideNewChannel)
    $('.new-channel-name').click((event) -> event.stopPropagation())

  onSelectActiveChannel: (event) =>
    target = $(event.target)
    location.href = "##{target.data("channelName")}"
    $(".channel.current").removeClass("current").mouseup(@onSelectActiveChannel)
    target.addClass("current").off("mouseup")

  hideNewChannel: (event) ->
    newChannelName = $('.new-channel-name')
    newChannelName.val('')
    newChannelName.hide()
    $('.add-channel-container').stop(true).animate({ width: '15px' }, 500, -> newChannelName.hide())
