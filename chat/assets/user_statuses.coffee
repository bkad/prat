# Everything having to do with the active users view

class window.Users
  @views: {}

  @init: (initialChannels) ->
    for channel in initialChannels
      @addUserStatusesView(channel)
      @displayUserStatuses(channel) if channel is CurrentChannel
    MessageHub.on("user_active user_offline", @updateUserStatus)
              .on("join_channel", @joinChannel)
              .on("leave_channel", @leaveChannel)
              .on("reconnect", @updateAllChannels)
              # We register a special callback for reconnection events because other events defer to it
              .onReconnect(@updateAllChannels)
    Channels.on("changeCurrentChannel", @displayUserStatuses)
            .on("leaveChannel", @removeUserStatuses)
            .on("joinChannel", @populateNewUserStatusesView)

  @updateAllChannels: =>
    $.ajax
      url: "/api/user_status"
      dataType: "json"
      success: @resetUserStatuses
      error: (xhr, textStatus, errorThrown) =>
        console.log "Error updating channels: #{textStatus}, #{errorThrown}"

  @resetUserStatuses: (channelsHash) =>
    for channel, users of channelsHash when @views[channel]
      @views[channel].collection.reset(users)

  @addUserStatusesIfNecessary: (users, channel) =>
    return unless @views[channel]?
    collection = @views[channel].collection
    for user in users
      collection.add(user) unless collection.get(user.email)

  @addUserStatusesView: (channel) =>
    usersCollection = new UserStatusCollection
    usersView = new UserStatusView(collection: usersCollection)
    $(".right-sidebar").append(usersView.$el)
    usersCollection.on("sort add remove reset", usersView.render)
    usersView.render()
    @views[channel] = usersView

  @populateNewUserStatusesView: (channel) =>
    @addUserStatusesView(channel)
    $.ajax
      url: "/api/user_status/#{encodeURIComponent(channel)}"
      dataType: "json"
      success: (data) =>
        @addUserStatusesIfNecessary(data, channel)

  @removeUserStatuses: (channel) =>
    return unless @views[channel]?
    usersView = @views[channel]
    delete @views[channel]
    usersView.remove()

  @displayUserStatuses: (channel) =>
    return unless @views[channel]?
    $(".channel-users.current").removeClass("current")
    @views[channel].$el.addClass("current")

  @updateUserStatus: (event, data) =>
    newStatus = event.split("_")[1]
    view = @views[data.channel]
    model = view.collection.get(data.user.email)
    if model?
      model.set(status: newStatus)
      view.collection.sort()
    else
      view.collection.add(data.user)

  @joinChannel: (event, data) =>
    collection = @views[data.channel].collection
    return if collection.get(data.user.email)?
    collection.add(data.user)

  @leaveChannel: (event, data) =>
    collection = @views[data.channel].collection
    collection.remove(data.user.email)

# attributes: name, email, gravatar, status
class UserStatus extends Backbone.Model
  initialize: (options) ->
    @attributes.isCurrentUser = @attributes.email is CurrentUserEmail

  idAttribute: "email"

class UserStatusCollection extends Backbone.Collection
  model: UserStatus

  comparator: (userA, userB) ->
    attrA = userA.attributes
    attrB = userB.attributes
    switch
      when attrA.isCurrentUser then -1
      when attrB.isCurrentUser then 1
      when attrA.status is "active" and attrB.status isnt "active" then -1
      when attrB.status is "active" and attrA.status isnt "active" then 1
      when attrA.name is attrB.name then 0
      when attrA.name < attrB.name then -1
      when attrA.name > attrB.name then 1

class UserStatusView extends Backbone.View
  initialize: ->
    @userStatusTemplate = $("#user-status-template").html()

  events: 
    "click .user-status" : "insertUserName"

  tagname: "div"
  className: "channel-users"

  insertUserName: (e) =>
    username = $(e.currentTarget).attr("data-original-title")
    ChatControls.appendUserName(username)

  renderUserStatus: (user) =>
    Util.$mustache(@userStatusTemplate, user.attributes).tooltip(DefaultTooltip)[0]

  renderUserStatusCollection: =>
    frag = document.createDocumentFragment()
    for status in @collection.map(@renderUserStatus)
      frag.appendChild(status)
    frag

  render: =>
    Util.cleanupTooltips()
    @$el.html(@renderUserStatusCollection())
    @
