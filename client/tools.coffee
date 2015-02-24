
### alerts ############################################################################################################

u.alert = (message, type = 'info', delay = 6000, offset = 0) ->
  $.bootstrapGrowl message,
    # ele: 'body'                          # which element to append to
    type:   type                           # null, 'info', 'error', 'success'
    offset: { from: 'top', amount: (Math.max offset, $('header').outerHeight() + 10) } # do not overlay header
    align:  (if type == 'info' then 'right' else 'center')                       # 'left', 'right', or 'center'
    width:  250                           # integer, or 'auto'
    delay:  delay
    allow_dismiss: (not (type in ['error', 'danger']))
    stackup_spacing: 10                  # spacing between consecutively stacked growls.

u.alert.warn = u.alert.warning = (message, delay, offset = 0) ->
  u.alert message, 'warning', delay, offset
u.alert.error = u.alert.danger = (message, delay = 8000, offset = 0) ->
  u.alert message, 'danger', delay, offset
u.alert.success = (message, delay, offset = 0) ->
  u.alert message, 'success', delay, offset
u.alert.info = (message, delay, offset = 0) ->
  u.alert message, 'info', delay, offset

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
  x = 0
  logr x = (c.outerWidth() - e.outerWidth()) / 2
  u.keepCompletelyVisible e, x, c.height(), c

u.keepCompletelyVisible = (element, x = 0, y, container = document, bounds = document) ->
  b = $ bounds; bo = u.offset b
  c = $ container; co = u.offset c
  e = $ element; w = e.outerWidth(); h = e.outerHeight(); y ?= co.top

  logmr 'keepCompletelyVisible: bo, co, x, y, w, h', bo, co, x, y, w, h
  #logmr '#########', e.width()
  #logmr '#########', e.outerWidth()
  #later 1, -> logmr '#########1', e.outerWidth()
  #later 10, -> logmr '#########2', e.outerWidth()
  #later 100, -> logmr '#########3', e.outerWidth()
  #later 1000, -> logmr '#########4', e.outerWidth() # only at 4 the outerWidth
  #is correct, might be due to the animation
  #later 10000, -> logmr '#########5', e.outerWidth()
  #logmr '#########', e.outerWidth true
  #logmr '#########', e.outerWidth true, true
  if (overflow = co.left + x + w - bo.right) > 0 then x -= overflow
  logmr '... right', x, overflow
  if (overflow = co.left + x) < 0 then x -= overflow
  logmr '... left', x, overflow
  if (overflow = co.top + y + h - bo.bottom) > 0 then y -= overflow
  logmr '... bottom', y, overflow
  if (overflow = co.top + y) < 0 then y -= overflow
  logmr '... top', y, overflow

  # if c.display:inline-block, e.left=0 does not place the element on the left side of c but on the left of the first letter in c, thus c delta x
  e.css 'left', 0
  cdx = co.left - e.offset().left
  logmr '... cdx', cdx
  #e.css 'left', cdx + x # also causes wierd behaviour somehow.
  e.css 'left', x
  e.css 'top', y
  #e.animate { left: cdx+x, top: y }, 50 will wait for other animations... dah!

Meteor.callCached ?= (method, parameters...) ->
  # TODO JSON.stringify parameters and add to sessionKey?
  sessionKey = "callCache_#{method}"
  (Session.get sessionKey) ? Meteor.apply method, parameters, (error, data) ->
    Session.set sessionKey, if error? then undefined else data
