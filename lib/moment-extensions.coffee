moment.fn.time ?= (hour = 0, min = 0, sec = 0, millis = 0) ->
  @hour(hour).minute(min).second(sec).millisecond(millis)
