class window.ChatControls
  constructor: (@messageHub, @channelViewCollection, leftClosed, rightClosed) ->
    @init(leftClosed, rightClosed)
    # When @currentAutocompletion is not null, it is a the tuple [list of matching usernames,
    # index of current match].
    @currentAutocompletion = null

  init: (leftSidebarClosed, rightSidebarClosed) =>
    rightToggle = if rightSidebarClosed then @onExpandRightSidebar else @onCollapseRightSidebar
    leftToggle = if leftSidebarClosed then @onExpandLeftSidebar else @onCollapseLeftSidebar
    $(".toggle-right-sidebar").one("click", rightToggle)
    $(".toggle-left-sidebar").one("click", leftToggle)
    @chatText = $("#chat-text")
    @chatText.on("keydown.return", @onChatSubmit)
    @chatText.on("keydown.up", @onPreviousChatHistory)
    @chatText.on("keydown.down", @onNextChatHistory)
    @chatText.on("keydown.esc", (e) -> $('#chat-text').blur())
    # Fix for jquery hotkeys messing up bootstrap modal dismissal
    $(document).on("keydown.esc", (e) -> $('#help').modal('hide'); $('#message-preview').modal('hide');)
    @chatText.on "keydown", @onChatAutocomplete
    @messageHub.on("force_refresh", @refreshPage)
    $(".chat-submit").click(@onChatSubmit)
    $(".chat-preview").click(@onPreviewSubmit)
    $("#preview-submit").click(@onPreviewSend)
    @currentMessage = ""
    @chatHistoryOffset = -1
    @globalBindings = [
        keys:['shift_/'],
        help:"Show this help dialog",
        showHelp: true,
        action: -> $('#help').modal("toggle")
      ,
        keys:['j'],
        help:"Next message",
        showHelp: true,
        action: -> Util.scrollMessagesDown()
      ,
        keys:['k'],
        help:"Previous message",
        showHelp: true,
        action: -> Util.scrollMessagesUp()
      ,
        keys:['shift_n'],
        help:"Next channel",
        showHelp: true,
        action: => @channelViewCollection.cycleChannel(1)
      ,
        keys:['shift_p'],
        help:"Previous channel",
        showHelp: true,
        action: => @channelViewCollection.cycleChannel(-1)
      ,
        keys:['shift_j'],
        help:"Join a new channel",
        showHelp: true,
        action: -> $(".add-channel-container").click()
      ,
        keys:['shift_g'],
        help:"Scroll to bottom",
        showHelp: true,
        action: => Util.scrollToBottom()
      ,
        keys:['return', '/'],
        help:"Focus chat box",
        showHelp: true,
        action: (e) ->
          e.preventDefault()
          $('#chat-text').focus()
    ]
    @initKeyBindings()

  onChatAutocomplete: (event) =>
    if event.which != 9
      # If not a tab, cancel any current autocomplete.
      @currentAutocompletion = null
      return

    event.preventDefault()

    position = @chatText[0].selectionStart
    firstPart = @chatText.val().substring(0, position)
    # Getting the current line before doing regexes is an optimization
    currentLine = firstPart.substring(firstPart.lastIndexOf("\n") + 1)
    users = []
    for model in channelUsers.views[channelViewCollection.currentChannel].collection.models
      users.push([model.attributes.username, model.attributes.name])

    # If there's nothing we're currently matching, then do a fresh autocomplete based on the current word.
    if @currentAutocompletion == null
      # Get the current word
      matches = /\s([^\s]*)$/.exec(currentLine)
      currentWord = if matches? then matches[1] else currentLine

      # Don't do anything unless the current word starts with '@'
      return unless currentWord.length > 0 && currentWord[0] == "@"
      currentWord = currentWord.substring(1)

      exactMatches = []
      inexactMatches = []
      for user in users
        # First check an exact match against the username
        if user[0].indexOf(currentWord) == 0
          exactMatches.push(user[0])
          continue
        # Now try a case-insensitive match against the username and real name
        lower = currentWord.toLowerCase()
        if user[0].toLowerCase().indexOf(lower) == 0 || user[1].toLowerCase().indexOf(lower) == 0
          inexactMatches.push(user[0])

      allMatches = exactMatches.concat(inexactMatches)
      return if allMatches.length == 0

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
    @insertTextAtCursor(@chatText[0], chosen)

  # http://stackoverflow.com/questions/7553430/javascript-textarea-undo-redo
  # This could also be done via the 'usual' method, which is basically copying all the text from the box,
  # manipulating it, pasting it all back in, and then putting the cursor in the right place.
  # Pros: This is way easier than that. undo/redo works with this method.
  # Cons: Deleting text requires a trick (select the text before emitting this event). Also, this doesn't work
  # in Firefox. Whatevs.
  insertTextAtCursor: (element, text) ->
    event = document.createEvent("TextEvent")
    event.initTextEvent("textInput", true, true, null, text)
    element.dispatchEvent(event)

  onPreviewSubmit: (event) =>
    message = @chatText.val()
    @messageHub.sendPreview(message, @channelViewCollection.currentChannel)

  onChatSubmit: (event) =>
    message = @chatText.val()
    if message.replace(/\s*$/, "") isnt ""
      @messageHub.sendChat(message, @channelViewCollection.currentChannel)
      @addToChatHistory(message)
    @chatText.val("").focus()
    event.preventDefault()

  onPreviewSend: =>
    $("#message-preview").modal("hide")
    @onChatSubmit(preventDefault: ->)

  onExpandRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-standard").html("right")
    $(".right-sidebar").removeClass("closed")
    $(".chat-column").removeClass("collapse-right")
    rightSidebarButton.one("click", @onCollapseRightSidebar)
    document.cookie = "rightSidebar=open"

  onCollapseRightSidebar: (event) =>
    rightSidebarButton = $(".toggle-right-sidebar")
    rightSidebarButton.find(".ss-standard").html("left")
    $(".right-sidebar").addClass("closed")
    $(".chat-column").addClass("collapse-right")
    rightSidebarButton.one("click", @onExpandRightSidebar)
    document.cookie = "rightSidebar=closed"

  onExpandLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-standard").html("left")
    $(".left-sidebar").removeClass("closed")
    $(".main-content").removeClass("collapse-left")
    leftSidebarButton.one("click", @onCollapseLeftSidebar)
    document.cookie = "leftSidebar=open"

  onCollapseLeftSidebar: (event) =>
    leftSidebarButton = $(".toggle-left-sidebar")
    leftSidebarButton.find(".ss-standard").html("right")
    $(".left-sidebar").addClass("closed")
    $(".main-content").addClass("collapse-left")
    leftSidebarButton.one("click", @onExpandLeftSidebar)
    document.cookie = "leftSidebar=closed"

  initKeyBindings: () =>
    helpDocumentation = []
    for b in @globalBindings
      if b.showHelp
        keys = []
        for key in b.keys
          keys.push({key:key.replace('shift_/', '?').replace(/_(?!$)/g, " + ")})
          if key != b.keys[b.keys.length-1]
            keys.push({sep: 'or'})
        helpDocumentation.push({keys:keys, helpMsg:b.help})
    rendered = Mustache.render($("#help-template").html(), bindings:helpDocumentation)
    $('body').append(rendered)
    $('#help').modal()
    for b in @globalBindings
      for key in b.keys
        $(document).on('keydown.'+ key, b.action)

  getChatHistory: ->
    JSON.parse(localStorage.getItem("chat_history"))

  setChatHistory: (history) ->
    localStorage.setItem("chat_history", JSON.stringify(history))

  getChatFromHistory: (history) ->
    history[history.length - @chatHistoryOffset - 1]

  onNextChatHistory: =>
    return unless @chatText.caret() is @chatText.val().length
    history = @getChatHistory()
    return unless history?.length > 0 and @chatHistoryOffset isnt -1
    @chatHistoryOffset--
    newValue = if @chatHistoryOffset is -1 then @currentMessage else @getChatFromHistory(history)
    @chatText.val(newValue)

  onPreviousChatHistory: =>
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

  addToChatHistory: (message) =>
    history = @getChatHistory()
    history ?= []
    history.push(message)
    history.shift() while history.length > 50

    @setChatHistory(history)
    @chatHistoryOffset = -1
    @currentMessage = ""
