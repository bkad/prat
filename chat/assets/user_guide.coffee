class window.UserGuide
  @init: ->
    shortcuts = @constructShortcuts()
    $template = Util.$mustache($("#info-template").html(), bindings: shortcuts)
    $("body").append($template)
    $("#info").modal()
    @nav("channels")
    $("#info-nav li").on "click", (e) => @nav($(e.target).attr("data-contents-pane"))
    $("#user-info-button").on "click", @showInfo

  @nav: (name) ->
    $old = $("#info-nav li.selected")
    $target = $("#info-nav li[data-contents-pane='#{name}']")
    $old.removeClass("selected")
    $target.addClass("selected")
    $oldPane = $("#info-contents .info-contents-pane.selected")
    $newPane = $("#info-contents .info-contents-pane.#{name}")
    $oldPane.removeClass("selected")
    $newPane.addClass("selected")

  @constructShortcuts: ->
    shortcuts = []
    for b in ChatControls.globalBindings
      if b.showHelp
        keys = []
        for key in b.keys
          keys.push(key: key.replace('shift_/', '?').replace(/_(?!$)/g, " + "))
          if key isnt b.keys[b.keys.length-1]
            keys.push(sep: 'or')
        shortcuts.push(keys:keys, purpose: b.help)
    shortcuts

  @showInfo: ->
    $("#info").modal("toggle")

  @showShortcuts: =>
    @nav("keyboard-shortcuts")
    @showInfo()
