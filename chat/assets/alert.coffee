# helper class for dealing with bootstrap alerts

class window.AlertHelper
  constructor: ->

  newAlert: (type, message) ->
  	@delAlert()
  	$(".alert-container").append($("<div class='alert " + type + "'>" + message + "<a class='close' data-dismiss='alert'>×</a></div>"))

  delAlert: ->
  	$(".alert").remove()
