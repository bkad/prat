window.Preferences =
  prefs:
    "alert-sounds":
      type: "boolean"
      default: true
    "webkit-nots":
      type: "boolean"
      default: false
    "swap-enter":
      type: "boolean"
      default: false
    "hide-images":
      type: "boolean"
      default: false

  get: (name) -> @prefs[name]?.value

  init: (initialPrefs) ->
    for name, pref of @prefs
      pref.value = if name of initialPrefs then initialPrefs[name] else pref.default

    $("#save-preferences").on "click", =>
      @save()
      $("#preferences").modal("hide")
    $("#preferences").on "hidden", => @setCheckboxesFromPrefs()
    $("#settings-button").on "click", @show
    $("#pref-webkit-nots").on "click", ->
      if window.webkitNotifications && $(this).prop("checked")
        window.webkitNotifications.requestPermission()

    @setCheckboxesFromPrefs()

  show: ->
    $("#preferences").modal("toggle")

  setCheckboxesFromPrefs: ->
    for name, pref of @prefs
      switch pref.type
        when "boolean"
          $("#pref-#{name}").attr("checked", pref.value)

  setPrefsFromCheckboxes: ->
    for checkbox in $("#preferences input[type='checkbox']")
      id = $(checkbox).attr("id")
      match = /^pref-(.*)$/.exec(id)
      continue unless match
      name = match[1]
      continue unless name of @prefs
      @prefs[name].value = checkbox.checked

  setPrefsFromServer: ->
    $.get "/api/user/preferences", (result) =>
      serverPrefs = JSON.parse(result)
      for name, pref of @prefs
        if name of serverPrefs
          switch pref.type
            when "boolean"
              pref.value = (serverPrefs[name] is true)
      @setCheckboxesFromPrefs()

  pushPrefsToServer: ->
    newPrefs = {}
    for name, pref of @prefs
      newPrefs[name] = pref.value
    $.ajax
      type: "PATCH"
      url: "/api/user/preferences"
      data: JSON.stringify(newPrefs)
      contentType: "application/json"

  save: ->
    @setPrefsFromCheckboxes()
    @pushPrefsToServer()
