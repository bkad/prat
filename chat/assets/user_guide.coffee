window.UserGuide =
  init: ->
    shortcuts = @constructShortcuts()
    rendered = Mustache.render($("#info-template").html(), bindings: shortcuts)
    $("body").append(rendered)
    $("#info").modal()
    $("#info-nav li").on "click", (e) => @nav($(e.target))

  nav: ($target) ->
    $old = $("#info-nav li.selected")
    return if $target.is($old)
    $old.removeClass("selected")
    $target.addClass("selected")
    newName = $target.attr("data-contents-pane")
    $oldPane = $("#info-contents .info-contents-pane.selected")
    $newPane = $("#info-contents .info-contents-pane.#{newName}")
    $oldPane.removeClass("selected")
    $newPane.addClass("selected")

  constructShortcuts: ->
    shortcuts = []
    for b in ChatControls.globalBindings
      if b.showHelp
        keys = []
        for key in b.keys
          keys.push({key: key.replace('shift_/', '?').replace(/_(?!$)/g, " + ")})
          if key != b.keys[b.keys.length-1]
            keys.push({sep: 'or'})
        shortcuts.push({keys:keys, purpose: b.help})
    shortcuts

  showInfo: ->
    $("#info").modal("toggle")

  showShortcuts: ->
    @nav($("#info-nav li[data-contents-pane='keyboard-shortcuts']"))
    @showInfo()
