# Everything having to do with the active users view

class window.ChannelUsers
  constructor: (@messageHub, initialUsers, currentChannel) ->
    @views = {}
    @init(initialUsers, currentChannel)
  init: (initialUsers, currentChannel) ->
    for channel, users of initialUsers
      view = @addUserStatuses(users, channel)
      @displayUserStatuses(channel) if channel is currentChannel
    @messageHub.on("user_active user_offline", @updateUserStatus)
    @messageHub.on("join_channel", @joinChannel)
    @messageHub.on("leave_channel", @leaveChannel)
  addUserStatuses: (users, channel) =>
    usersCollection = new UserStatusCollection(users)
    usersView = new UserStatusView(collection: usersCollection)
    $(".right-sidebar").append(usersView.$el)
    usersCollection.on("change add remove reset", usersView.render)
    usersView.render()
    @views[channel] = usersView
  removeUsersStatuses: (channel) =>
    return unless @views[channel]?
    usersView = @views[channel]
    delete @views[channel]
    usersView.remove()
  displayUserStatuses: (channel) =>
    return unless @views[channel]?
    $(".channel-users.current").removeClass("current")
    @views[channel].$el.addClass("current")
  updateUserStatus: (event, data) =>
    newStatus = event.split("_")[1]
    for channel, view of @views
      model = view.collection.get(data.email)
      if model?
        model.set(status: newStatus)
        view.collection.sort()
  joinChannel: (event, data) =>
    collection = @views[data.channel].collection
    return if collection.get(data.user.email)?
    collection.add(data.user)
  leaveChannel: (event, data) =>
    collection = @views[data.channel].collection
    collection.remove(data.email)

# attributes: name, email, gravatar, status
class window.UserStatus extends Backbone.Model
  initialize: (arguments) ->
    @attributes.isCurrentUser = @attributes.email is CurrentUserEmail
  idAttribute: "email"

class window.UserStatusCollection extends Backbone.Collection
  model: UserStatus
  comparator: (userA, userB) ->
    attrA = userA.attributes
    attrB = userB.attributes
    if attrA.isCurrentUser
      -1
    else if attrB.isCurrentUser
      1
    else if attrA.status is "active" and attrB.status isnt "active"
      -1
    else if attrB.status is "active" and attrA.status isnt "active"
      1
    else if attrA.name is attrB.name
      0
    else if attrA.name < attrB.name
      -1
    else if attrA.name > attrB.name
      1

class window.UserStatusView extends Backbone.View
  initialize: ->
    @userStatusTemplate = $("#user-status-template").html()
  tagname: "div"
  className: "channel-users"
  renderUserStatus: (user) =>
    Mustache.render(@userStatusTemplate, user.attributes)
  renderUserStatusCollection: =>
    @collection.map(@renderUserStatus).join("")
  render: =>
    @$el.html(@renderUserStatusCollection())
    @
