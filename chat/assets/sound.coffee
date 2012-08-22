# helper class for dealing with the HTML5 audio API

class window.Sound
  constructor: (@newMessageAudioLocation) ->
    @first = true
    @init()

  init: ->
    @context = new webkitAudioContext()
    @loadNewMessageAudio(@newMessageAudioLocation1)

  loadNewMessageAudio: (location, buffer) ->
    request = new XMLHttpRequest()
    request.open("GET", @newMessageAudioLocation, true)
    request.responseType = "arraybuffer"
    request.onload = =>
      @context.decodeAudioData(request.response, ((buffer) => @newMessageAudio = buffer))
    request.send()

  playNewMessageAudio: ->
    return unless @newMessageAudio?
    source = @context.createBufferSource()
    source.buffer = @newMessageAudio
    source.connect(@context.destination)
    source.noteOn(0)
