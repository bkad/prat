# Everything having to do with the active users view

class window.ChannelUsers
  constructor: (@messageHub, @initialUsers, currentChannel, channelViewCollection) ->
    @views = {}
    @init(currentChannel, channelViewCollection)

  init: (currentChannel, channelViewCollection) ->
    for channel, users of @initialUsers
      @addUserStatusesView(channel)
      @displayUserStatuses(channel) if channel is currentChannel
    @messageHub.on("user_active user_offline", @updateUserStatus)
               .on("join_channel", @joinChannel)
               .on("leave_channel", @leaveChannel)
               .on("reconnect", @updateAllChannels)
    @messageHub.blockDequeue()
    channelViewCollection.on("changeCurrentChannel", @displayUserStatuses)
                         .on("leaveChannel", @removeUserStatuses)
                         .on("joinChannel", @populateNewUserStatusesView)

  updateAllChannels: =>
    $.ajax
      url: "/api/user_status"
      dataType: "json"
      success: @resetUserStatuses
      error: (xhr, textStatus, errorThrown) =>
        console.log "Error updating channels: #{textStatus}, #{errorThrown}"
      complete: =>
        @messageHub.unblockDequeue()

  resetUserStatuses: (channelsHash) =>
    for channel, users of channelsHash
      continue unless @views[channel]
      @views[channel].collection.reset(users)

  addUserStatusesIfNecessary: (users, channel) =>
    return unless @views[channel]?
    collection = @views[channel].collection
    for user in users
      collection.add(user) unless collection.get(user.email)

  populateInitialUserStatuses: =>
    for channel, users of @initialUsers
      @addUserStatusesIfNecessary(users, channel)

  addUserStatusesView: (channel) =>
    usersCollection = new UserStatusCollection
    usersView = new UserStatusView(collection: usersCollection)
    $(".right-sidebar").append(usersView.$el)
    usersCollection.on("change add remove reset", usersView.render)
    usersView.render()
    @views[channel] = usersView

  populateNewUserStatusesView: (channel) =>
    @addUserStatusesView(channel)
    $.ajax
      url: "/api/user_status/#{encodeURIComponent(channel)}"
      dataType: "json"
      success: (data) =>
        @addUserStatusesIfNecessary(data, channel)

  removeUserStatuses: (channel) =>
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
    view = @views[data.channel]
    model = view.collection.get(data.user.email)
    if model?
      model.set(status: newStatus)
      view.collection.sort()
    else
      view.collection.add(data.user)

  joinChannel: (event, data) =>
    collection = @views[data.channel].collection
    return if collection.get(data.user.email)?
    collection.add(data.user)

  leaveChannel: (event, data) =>
    collection = @views[data.channel].collection
    collection.remove(data.user.email)


# attributes: name, email, gravatar, status
class window.UserStatus extends Backbone.Model
  initialize: (options) ->
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
    Util.cleanupTipsy()
    @$el.html(@renderUserStatusCollection())
    @


