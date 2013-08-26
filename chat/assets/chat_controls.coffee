class window.ChatControls
  @globalBindings: [
      keys: ['shift_/']
      help: "Show this help dialog"
      showHelp: true
      action: -> UserGuide.showShortcuts()
    ,
      keys: ['j']
      help: "Next message"
      showHelp: true
      action: -> Util.scrollMessagesDown()
    ,
      keys: ['k']
      help: "Previous message"
      showHelp: true
      action: -> Util.scrollMessagesUp()
    ,
      keys: ['shift_n']
      help: "Next channel"
      showHelp: true
      action: -> Channels.cycleChannel(1)
    ,
      keys: ['shift_p']
      help: "Previous channel"
      showHelp: true
      action: -> Channels.cycleChannel(-1)
    ,
      keys: ['shift_j']
      help: "Join a new channel"
      showHelp: true
      action: -> Channels.showNewChannel()
    ,
      keys: ['shift_g']
      help: "Scroll to bottom"
      showHelp: true
      action: -> Util.scrollToBottom()
    ,
      keys: ['return', '/']
      help: "Focus chat box"
      showHelp: true
      action: (e) ->
        e.preventDefault()
        $('#chat-text').focus()
  ]

  @init: (options) =>
    # When @currentAutocompletion is not null, it is a the tuple [list of matching usernames,
    # index of current match].
    @currentAutocompletion = null
    for direction in ["left", "right"]
      $(".toggle-#{direction}-sidebar").one("click",
        @sidebarAccordian(placement: direction, expand: options["#{direction}SidebarClosed"]))
    @chatText = $("#chat-text")
    @chatText.on("keydown.shift_return", (e) => @onReturn(e, true))
    @chatText.on("keydown.return", (e) => @onReturn(e, false))
    @chatText.on("keydown.up", @onPreviousChatHistory)
    @chatText.on("keydown.down", @onNextChatHistory)
    # TODO(kle): figure out why we have to close over blur
    @chatText.on("keydown.esc", => @chatText.blur())
    # Fix for jquery hotkeys messing up bootstrap modal dismissal
    $(document).on("keydown.esc", @hideModals)
    @chatText.on "keydown", @onChatAutocomplete
    MessageHub.on("force_refresh", @refreshPage)
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-preview").click(@onPreviewSubmit)
    $("#preview-submit").click(@onPreviewSend)
    @currentMessage = ""
    @chatHistoryOffset = -1
    @initKeyBindings()

  @onReturn: (e, shift) ->
    @onChatSubmit(e) if shift is Preferences.get("swap-enter")

  @onChatAutocomplete: (event) =>
    if event.which isnt 9
      # If not a tab, cancel any current autocomplete.
      @currentAutocompletion = null
      return

    event.preventDefault()

    position = @chatText[0].selectionStart
    firstPart = @chatText.val().substring(0, position)
    # Getting the current line before doing regexes is an optimization
    currentLine = firstPart.substring(firstPart.lastIndexOf("\n") + 1)
    users = []
    for model in Users.views[CurrentChannel].collection.models
      users.push([model.attributes.username, model.attributes.name])

    # If there's nothing we're currently matching, then do a fresh autocomplete based on the current word.
    if @currentAutocompletion is null
      # Get the current word
      matches = /\s([^\s]*)$/.exec(currentLine)
      currentWord = if matches? then matches[1] else currentLine

      # Don't do anything unless the current word starts with '@'
      return unless currentWord.length > 0 and currentWord[0] is "@"
      currentWord = currentWord.substring(1)

      exactMatches = []
      inexactMatches = []
      for user in users
        # First check an exact match against the username
        if user[0].indexOf(currentWord) is 0
          exactMatches.push(user[0])
          continue
        # Now try a case-insensitive match against the username and real name
        lower = currentWord.toLowerCase()
        if user[0].toLowerCase().indexOf(lower) is 0 or user[1].toLowerCase().indexOf(lower) is 0
          inexactMatches.push(user[0])

      allMatches = exactMatches.concat(inexactMatches)
      return if allMatches.length is 0

      @currentAutocompletion = [allMatches, 0]
      chosen = allMatches[0] + " "

      # Select the current word, so that when we insert text it will overwrite it.
      @chatText[0].setSelectionRange(position - currentWord.length, position)

    # Otherwise, rotate to the next user entry matching the current autocomplete.
    else
      # Get the current autocomplete suggestion
      window.line = currentLine
      matches = /@([^\s]+) $/.exec(currentLine)
      if matches?
        currentMatch = matches[1]
      else
        # Weird state
        @currentAutocompletion = null
        return

      # Rotate to the next matching user entry.
      @currentAutocompletion[1] = (@currentAutocompletion[1] + 1) % @currentAutocompletion[0].length
      chosen = @currentAutocompletion[0][@currentAutocompletion[1]] + " "

      # Select the current match and the following space, so the text insertion overwrites it.
      @chatText[0].setSelectionRange(position - currentMatch.length - 1, position)

    # Now we have the substitute word, and the replacement text is highlighted.
    Util.insertTextAtCursor(@chatText[0], chosen)

  @onPreviewSubmit: (event) =>
    message = @chatText.val()
    MessageHub.sendPreview(message, CurrentChannel)

  @onChatSubmit: (event) =>
    message = @chatText.val()
    if message.replace(/\s*$/, "") isnt ""
      MessageHub.sendChat(message, CurrentChannel)
      @addToChatHistory(message)
    @chatText.val("").focus()
    event.preventDefault()

  @onPreviewSend: =>
    $("#message-preview").modal("hide")
    @onChatSubmit(preventDefault: ->)

  @sidebarAccordian: (options) =>
    (event) =>
      placement = options.placement
      expand = options.expand
      button = $(".toggle-#{placement}-sidebar")
      classCondition = ((placement is "left" and expand) or (placement is "right" and not expand))
      iconClass = "icon-chevron-" + if classCondition then "left" else "right"
      button.find("span").attr("class", iconClass)
      classAttrMethod = "#{if expand then "remove" else "add"}Class"
      $(".#{placement}-sidebar")[classAttrMethod]("closed")
      $(".chat-column")[classAttrMethod]("collapse-#{placement}")
      button.one("click", @sidebarAccordian(placement: placement, expand: not expand))
      document.cookie = "#{placement}Sidebar=#{if expand then "open" else "closed"}"

  @initKeyBindings: =>
    for b in @globalBindings
      for key in b.keys
        $(document).on('keydown.'+ key, b.action)

  @getChatHistory: ->
    JSON.parse(localStorage.getItem("chat_history"))

  @setChatHistory: (history) ->
    localStorage.setItem("chat_history", JSON.stringify(history))

  @getChatFromHistory: (history) ->
    history[history.length - @chatHistoryOffset - 1]

  @onNextChatHistory: =>
    return unless @chatText.caret() is @chatText.val().length
    history = @getChatHistory()
    return unless history?.length > 0 and @chatHistoryOffset isnt -1
    @chatHistoryOffset--
    newValue = if @chatHistoryOffset is -1 then @currentMessage else @getChatFromHistory(history)
    @chatText.val(newValue)

  @onPreviousChatHistory: =>
    return unless @chatText.caret() is 0
    if @chatHistoryOffset is -1
      @currentMessage = @chatText.val()
    history = @getChatHistory()
    return unless history?.length > 0
    if @chatHistoryOffset is history.length-1
      @chatText.val(history[0])
    else
      @chatHistoryOffset++
      @chatText.val(@getChatFromHistory(history))

  @addToChatHistory: (message) =>
    history = @getChatHistory()
    history ?= []
    history.push(message)
    history.shift() while history.length > 50

    @setChatHistory(history)
    @chatHistoryOffset = -1
    @currentMessage = ""

  @hideModals: ->
    $("#info").modal("hide")
    $("#message-preview").modal("hide")

  @appendUserName: (username) =>
    currentMessage = @chatText.val().trim()
    @chatText.focus().val((currentMessage + " @" + username).trim())
