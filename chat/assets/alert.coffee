# helper class for dealing with bootstrap alerts

class window.AlertHelper
  constructor: ->

  newAlert: (type, message) ->
    @delAlert()
    rendered = Mustache.render($("#alert-template").html(), type: type, message: message)
    $(".alert-container").append(rendered)

  delAlert: ->
    $(".alert").remove()
