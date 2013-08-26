class BooleanPreferenceView extends Backbone.View
  events:
    "change input": "setValue"

  tagName: "label"

  initialize: (options) ->
    @value = options.value ? options.default

  setValue: =>
    @value = @$el.find("input").is(":checked")
    patchBody = {}
    patchBody[@options.name] = @value
    $.ajax
      type: "PATCH"
      url: "/api/user/preferences"
      data: JSON.stringify(patchBody)
      contentType: "application/json"

  render: ->
    template = $("#boolean-preference-template").html()
    @$el.html(Util.mustache(template, description: @options.description))
        .find("input").attr("checked", @value)
    @


window.Preferences =
  prefs:
    "alert-sounds":
      default: true
      description: "Play an alert sound when you are mentioned and the chat window is not focused."
    "webkit-nots":
      default: false
      description: "Show a notification when a new message is received."
    "swap-enter":
      default: false
      description: "In the input box, <code>enter</code> inserts a newline and <code>shift</code>+<code>enter</code> sends a message."
    "hide-images":
      default: false
      description: "Auto-hide all images/YouTube videos in new messages."

  get: (name) -> @prefs[name].view.value

  init: (initialPrefs) ->
    for name, pref of @prefs
      @prefs[name].view = view = new BooleanPreferenceView
        value: initialPrefs[name]
        description: pref.description
        default: pref.default
        name: name
      $("#preferences .modal-body").append(view.render().el)

    $("#settings-button").on "click", @show
    $("#pref-webkit-nots").on "click", ->
      if $(@).prop("checked")
        webkitNotifications?.requestPermission()

  show: ->
    $("#preferences").modal("toggle")
