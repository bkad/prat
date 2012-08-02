class window.DateTime
  @MONTHS: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
  @DAYS: ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  @DAY_MILLISECONDS: 1000 * 60 * 60 * 24

  constructor: (@unixTime) ->
    @posted = new Date(@unixTime * 1000)
    @year = @posted.getFullYear()
    @date = @posted.getDate()
    @weekday = DateTime.DAYS[@posted.getDay()]
    @month = DateTime.MONTHS[@posted.getMonth()]
    @hours = @posted.getHours()
    @minutes = @posted.getMinutes()
    @minutes = if @minutes < 10 then "0#{@minutes}" else @minutes

    am = true
    if @hours > 12
      am = false
      @hours -= 12
    else if @hours == 12
      am = false
    else if @hours == 0
      @hours = 12

    @amPM = if am then "AM" else "PM"

  contextualTime: ->
    now = new Date()
    diff = now.getTime() / 1000 - @unixTime
    diffMinutes = Math.round(diff / 60)
    diffHours = Math.round(diffMinutes / 60)
    daysBetween = Math.round((now.getTime() - @posted.getTime()) / DateTime.DAY_MILLISECONDS)

    time = "#{@hours}:#{@minutes} #{@amPM}"

    if diffMinutes < 1 then "a moment ago"
    else if diffMinutes == 1 then "a minute ago"
    else if diffMinutes < 60 then "#{diffMinutes} minutes ago"
    else if diffHours == 1 then "an hour ago"
    else if diffHours < 11 then "#{diffHours} hours ago"
    else if @date == now.getDate() then time
    else if @date == now.getDate() - 1 then "yesterday at #{time}"
    else if daysBetween < 7 then "#{@weekday} at #{time}"
    else if daysBetween < 365 then "#{@date} #{@month} #{time}"
    else "#{@date} #{@month} #{time}"

class window.DateTimeHelper
  constructor: ->
    @init()

  init: ->
    @setUpdateTimestampsInterval(60000)

  bindOne: (timeContainer) ->
    timeContainer.data("datetime", new DateTime(parseInt(timeContainer.attr("data-time"))))

  removeBindings: (timeContainer) -> timeContainer.removeData("datetime")

  updateTimestamps: =>
    $(".author-container .time").each((index, timeContainer) => @updateTimestamp($(timeContainer)))

  updateTimestamp: (timeContainer) ->
    timeContainer.html(timeContainer.data("datetime").contextualTime())

  setUpdateTimestampsInterval: (interval) ->
    @intervalID = setInterval(@updateTimestamps, interval)

  clearUpdateTimestampsTimeout: -> clearInterval(@intervalID?)
