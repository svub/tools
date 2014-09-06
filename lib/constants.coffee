# The global u object... u as in util. Not t as in tools, yep.
@u =
  url: Meteor.absoluteUrl()
  dateFormat: 'llll' # 'YYYY-MM-DD'
  momentDateFormat: year = 'YYYY-MM-DD'
  #momentDateBeautifulFormat: 'LL'
  momentDateBeautifulFormat: 'dddd, MMMM D YYYY'
  momentDateXShortFormat: xMonth = 'MMM D'
  momentDateShortFormat: month = 'MMMM D'
  momentTimeXShortFormat: xTime = 'H:mm'
  momentTimeShortFormat: time = 'HH:mm'
  momentDateTimeFormat: 'YYYY-MM-DD HH:mm'
  #momentDateTimeBeautifulFormat: 'LLL'
  momentDateTimeBeautifulFormat: 'dddd, MMMM D YYYY H:mm'
  momentDateTimeShortFormat: 'ddd, MMM D HH:mm'
  momentDateFormats: dateFormats = [xMonth, month, year]
  momentTimeFormats: timeFormats = ["#{xMonth} #{xTime}", "#{month} #{time}", "ddd, #{xMonth} #{xTime}", "dddd, #{month} #{time}", "dddd, #{month} YYYY #{time}"]
  momentFormats: _.union dateFormats, timeFormats
  format: (d, detail = 0) -> moment(d).format u.momentFormats[detail]
  defaultLang: 'en'
  empty: {}
  cb: -> logr.apply @, arguments
  l: {} # locations, methods for working with lat/lng geo data
  x: {} # extenal webservice wrapper
