# helper class for dealing with bootstrap alerts

class window.AlertHelper
  constructor: ->

  newAlert: (type, message) ->
    @delAlert()
    rendered = Util.mustache($("#alert-template").html(), type: type, message: message)
    $(".alert-container").append(rendered)

  timedAlert: (type, message, time) ->
    @delAlert()
    rendered = Util.mustache($("#alert-template").html(), type: type, message: message)
    $(".alert-container").append(rendered)
    window.setTimeout(delAlert, time)

  delAlert: ->
    $(".alert").remove()