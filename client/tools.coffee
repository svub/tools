
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
u.alert.info = (message, delay) -> u.alert message, 'info', delay

u.events = (e, map) ->
  for type, fn of map
    if fn? then e.on type, fn

u.fillText = (selector, options={}) ->
  [selector, options] = [null, selector] unless _.isString selector
  log o = $.extend { start: 100; step: 10; max: 100 }, options
  ($ selector ? o.selector ? '.fill-text').each ->
    e = $ @; w = e.width(); h = e.height(); c = e.html()
    #logmr 'w, h', w, h
    if (i = $ '.fill-text-inner', e).length > 0 then c = i.html()
    e.addClass('fill-text').empty()
    if clearDim = (e.height() < h or e.width() < w)
      u.setDimensions e, w, h, 'px'
    i = $('<div class="fill-text-inner">').html(c).appendTo e
    setFontSize = (el, x) -> el.css 'font-size', "#{o.start+x*o.step}%"; x
    for x in [0..o.max]
      setFontSize i, x
      #logmr 'x, sW, sH', x, i[0].scrollWidth, i[0].scrollHeight
      if i[0].scrollWidth > w or i[0].scrollHeight > h
        if clearDim then u.setDimensions e
        return setFontSize i, x-1
        #e.empty().html c
        #return setFontSize e, x-1

u.setDimensions = (element, width='', height='', unit = 'px') ->
  width = "#{width}#{unit}" if _.isNumber width
  height = "#{height}#{unit}" if _.isNumber height
  element.css 'width', width
  element.css 'height', height

u.offset = (element = document) ->
  e = $ element; o = e.offset() ? top: 0, left: 0
  o.right = o.left + e.outerWidth()
  o.bottom = o.top + e.outerHeight()
  o

u.showBelow = (element, container = document) ->
  e = $ element; c = $ container; co = c.offset()
  u.keepCompletelyVisible e, 0, c.height(), c

u.keepCompletelyVisible = (element, x = 0, y, container = document, bounds = document) ->
  b = $ bounds; bo = u.offset b
  c = $ container; co = c.offset(); cdx =
  e = $ element; w = e.outerWidth(); h = e.outerHeight(); y ?= co.top

  if (overflow = co.left + x + w - bo.right) > 0 then x -= overflow
  if (overflow = co.left + x) < 0 then x -= overflow
  if (overflow = co.top + y + h - bo.bottom) > 0 then y -= overflow
  if (overflow = co.top + y) < 0 then y -= overflow

  # if c.display:inline-block, e.left=0 does not place the element on the left side of c but on the left of the first letter in c, thus c delta x
  e.css 'left', 0; cdx = co.left - e.offset().left
  e.css 'left', cdx + x
  e.css 'top', y

Meteor.callCached ?= (method, parameters...) ->
  # TODO JSON.stringify parameters and add to sessionKey?
  sessionKey = "callCache_#{method}"
  (Session.get sessionKey) ? Meteor.apply method, parameters, (error, data) ->
    Session.set sessionKey, if error? then undefined else data
