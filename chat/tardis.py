import calendar

def datetime_to_unix(utc_datetime):
  return int(calendar.timegm(utc_datetime.timetuple()))
