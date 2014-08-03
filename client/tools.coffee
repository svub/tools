
### alerts ############################################################################################################

u.alert = (message, type = 'info', delay = 6000) ->
  $.bootstrapGrowl message,
    # ele: 'body'                          # which element to append to
    type:   type                           # null, 'info', 'error', 'success'
    offset: { from: 'top', amount: ($('header').outerHeight() + 10) } # do not overlay header
    align:  (if type == 'info' then 'right' else 'center')                       # 'left', 'right', or 'center'
    width:  250                           # integer, or 'auto'
    delay:  delay
    allow_dismiss: (not (type in ['error', 'danger']))
    stackup_spacing: 10                  # spacing between consecutively stacked growls.

u.alert.warn = u.alert.warning = (message, delay) ->
  u.alert message, 'warning', delay
u.alert.error = (message, delay = 8000) -> u.alert message, 'danger', delay
u.alert.success = (message, delay) -> u.alert message, 'success', delay
u.events = (e, map) ->
  for type, fn of map
    if fn? then e.on type, fn

u.fillText = (selector, options={}) ->
  [selector, options] = [null, selector] unless _.isString selector
  o = $.extend { start: 100; step: 10; max: 100 }, options
  ($ selector ? '.fill-text').each ->
    e = $ @; w = e.width(); h = e.height(); c = e.html()
    e.addClass('fill-text').empty()
    i = $('<div>').html(c).appendTo e
    setFontSize = (el, x) -> el.css 'font-size', "#{o.start+x*o.step}%"; x
    for x in [0..o.max]
      setFontSize i, x
      if i[0].scrollWidth > w or i[0].scrollHeight > h
        return setFontSize i, x-1

Meteor.callCached ?= (method, parameters...) ->
  # TODO JSON.stringify parameters and add to sessionKey?
  sessionKey = "callCache_#{method}"
  (Session.get sessionKey) ? Meteor.apply method, parameters, (error, data) ->
    Session.set sessionKey, if error? then undefined else data
