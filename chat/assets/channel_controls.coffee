class window.ChannelControls
  constructor: ->
    $(".channel:not(.active)").mouseup(@onSelectActiveChannel)

  onSelectActiveChannel: (event) =>
    $(".channel.current").removeClass("current").mouseup(@onSelectActiveChannel)
    $(event.target).addClass("current").off("mouseup")
