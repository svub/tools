Match.OptionalOrNull = (pattern) -> Match.OneOf undefined, null, pattern
Meteor.acall = (name, args...) -> Meteor.call.apply @, _.flatten [name, args, (->)]

_s.hash ?= `function (str) {
  var hash = 0, len = str.length
  if (len == 0) return hash;
  for (var i = 0; i < len; i++) {
    hash = hash * 31 + str.charCodeAt(i);
  }
  return hash;
}`
_s.match ?= (string1, string2, similarity=.75) -> (1-_.levenshtein(string1, string2)/Math.max(string1?.length, string2?.length)) >= similarity
_s.startsWithI = (string, part) ->
  _s.startsWith string?.toLowerCase(), part?.toLowerCase()

Array.prototype.clone = -> @slice 0
Array.prototype.chop = (partSize) ->
  array = @clone()
  (array.splice 0, partSize until array.length <= 0)
Array.prototype.split = (pieces) ->
  @chop Math.ceil @length/pieces
Array.prototype.copy = -> @slice()
Array.prototype.pushAll = (array) ->
  if array?.length > 0 then @push obj for obj in array
  @
#_.mixin
#  'chop': (array, partSize) ->
#    array = @clone array
#    (array.splice 0, partSize until array.length <= 0)
#  'split': (array, pieces) ->
#    @chop array, Math.ceil array.length/pieces
#  'pushAll': (array, all) ->
#    if all?.length > 0 then array.push obj for obj in all
#    array

u.addCommonMethods = (object, collection, defaultRoute, getLabel) -> _.extend object,
  get: (id) -> if _.isString id then collection.findOne { _id: id } else id
  findAll: (ids) ->
    try
      if collection.findAll? then collection.findAll ids
      else Meteor.Collection.prototype.findAll.apply collection, [ids]
    catch e
      loge e
  getAll: (ids) -> if isEmpty ids then [] else @findAll(ids)?.fetch()
  label: (obj) -> getLabel obj
  url: (obj, route = defaultRoute) -> if (obj = @get obj)? then Router.url route, obj
  link: (obj, route = defaultRoute, label) ->
    if (obj = @get obj)? then "<a href=\"#{@url obj, route}\">#{label ? @label obj}</a>" else label
  goTo: (obj, route = defaultRoute) ->
    Router.go route, obj

### logging ###########################################################################################################

#u._loggingEnabled = -> Session?.get?('loggingEnabled') ? (Meteor?.isServer or window?.location?.href?.indexOf?('localhost')>=0)
u._loggingEnabled = (enable) -> Deps.nonreactive ->
  if enable? then Session.set 'loggingEnabled', enable
  Session?.get?('loggingEnabled') ? (Meteor?.isServer or (window?.location?.href?.indexOf?('localhost')>=0))
u._logStartTime = moment()
u._getTimeStamp = -> _s.pad((moment()-u._logStartTime).valueOf(), 6) + ' '
u.log = @log = (obj) =>
  try
    u.logr u._getTimeStamp()+(if _.isString obj then obj else JSON.stringify obj)
  catch error
    console.log "error in log:"
    console.log error.stack
  obj
u.logt = @logt = (msg) =>
  u.log msg
  console.trace()
u.logr = @logr = (objs...) =>
  return objs[0] unless u._loggingEnabled()
  try
    #console.log obj
    console.log.apply console, objs
    #if ("" + obj).toLowerCase().indexOf("error") >= 0 then console.trace()
  catch error
    console.log "error in logr:"
    console.log error.stack
  objs[0]
u.logm = @logm = (msg, obj) =>
  try
    u.logr u._getTimeStamp()+msg+": "+JSON.stringify obj
  catch error
    console.log "error in logm: msg=#{msg}"
    console.log error.stack
  obj
u.logmr = @logmr = (msg, objs...) =>
  try
    # console.log "#{msg}: #{obj}"
    #u.logr u._getTimeStamp()+"#{msg}: "
    #u.logr obj
    u.logr.apply u, _.union [u._getTimeStamp()+"#{msg}: "], objs
  catch error
    console.log "error in logmr: msg=#{msg}"
    console.log error.stack
  objs[0]
u.logmkv = @logmkv = (msg, obj) =>
  try
    u.logr u._getTimeStamp()+"#{msg}: " + (for k,v of obj
      if typeof v == "function" then "#{k}=f(...)\n" else "#{k}=#{v}\n")
  catch error
    console.log "error in logmkv: msg=#{msg}"
    console.log error.stack
  obj
u.logme = @logme = (m, e) ->
  try
    log m
    loge e
u.loge = @loge = (e) =>
  try
    if e?
      if e.message?
        if e.stack? then u.logr(u._getTimeStamp()+'Caught error: ' + e.message + "\n" + e.stack)
        else u.logr(u._getTimeStamp()+'Caught error: ' + e.message)
      else u.logr(u._getTimeStamp()+'Caught error: ' + e)
    else u.logr 'No error'
  catch
    # console.log 'Error while logging error'
    # console.trace()

### helpers ###########################################################################################################

@debounce = (time, fn) -> _.debounce fn, time
@throttle = (time, fn) -> _.throttle fn, time
@between = (value, min, max) -> Math.max min, Math.min max, value
@parseNumberOr = (value, otherwise = 0, parser = parseFloat) ->
  if _.isNumber value then value
  else if _.isArray value then value[i] = parseNumberOr v, otherwise, parser for v,i in value
  else unlessNaN (parser value), otherwise
@parseIntOr = (value, otherwise = 0) -> parseNumberOr value, otherwise, parseInt
@parseFloatOr = (value, otherwise = 0) -> parseNumberOr value, otherwise, parseFloat
@unlessNaN = (value, otherwise) -> unless _.isNaN value then value else otherwise
@doAndReturnIf = (data, fn) -> doAndReturn data, -> fn data if data?
@doAndReturn = (data, fn) ->
  fn data
  data
@maybe = u.rif = (data, condition, fn) ->
  if _.isFunction condition then condition = condition data
  if condition then fn data else data
@rif = u.rif = (condition, data, otherwise) ->
  if _.isFunction condition then condition = condition data
  if condition then data else
    if _.isFunction otherwise then otherwise data
    else otherwise

@maybeFilter = (data, condition, filter) ->
  if data?
    if _.isFunction condition then condition = condition data
    if condition then data = _.filter data, filter
  data
u.with = @with = (object, block) -> block.call object
u.withIf = @withIf = (object, block) -> u.with object, block if object?

@transform = (data, fn) ->
  results = if _.isArray data then [] else {}
  if data?
    for item,key in data
      if (transformed = fn item)? then results[key] = transformed
  results

@firstNonEmpty = u.firstNonEmpty = (choices...) -> if choices?
  return choice for choice in choices when (notEmpty choice)?

u.createObject = @createObject = ->
  object = {}
  for o,i in arguments
    if i%2==1 and (key = arguments[i-1])? then object[key] = o
  object
u.asArray = @asArray = (something) ->
  if something?
    if _.isArray something then something else [something]
  else []
u.asBoolean = @asBoolean = (something, otherwise = false) ->
  if _.isBoolean something then something
  else
    switch something?.trim?()?.toLowerCase?()
      when 'yes', 'true', 'on' then true
      when 'no', 'false', 'off' then false
      else otherwise
u.notEmpty = @notEmpty = (stringOrArray, toBeRemoved...) ->
  if (o = stringOrArray)?
    if _.isString o then o = _.trim(o)
    if toBeRemoved? and toBeRemoved.length > 0 then o = u.removeAll o, _.flatten(toBeRemoved)
    if o.length > 0 then o else null
  else null
u.removeAll = (stringOrArray, toBeRemoved...) ->
  unless stringOrArray?.length then return stringOrArray
  toBeRemoved = _.flatten toBeRemoved
  if _.isArray stringOrArray
    toBeRemoved.unshift stringOrArray
    _.without.apply _, toBeRemoved
  else for remove in toBeRemoved
    # logm "u.removeAll #{stringOrArray}", remove
    stringOrArray = stringOrArray.replace remove, ''
  return stringOrArray
u.replaceAll = (string, map) ->
  if string?.length and map?
    string = string.replace (new RegExp k), v for own k,v of map
  string

u.isEmpty = @isEmpty = (stringOrArray, toBeRemoved...) ->
  not notEmpty(stringOrArray, toBeRemoved)?
u.extend = (obj, extension) ->
  for name, attr of extension
    obj[name] = if typeof attr == 'function' then _.bind attr, obj else attr
  obj
u.extend2 = u.extendAndBind = (obj, extension) ->
  check obj, Match.OneOf Object, Function
  for name, attr of extension
    if typeof attr == 'function'
      (() ->
        bound = _.bind attr, obj
        obj[name] = -> bound @)()
    else obj[name] = attr
    # logmr "#{name}", obj[name]
  obj
u.getLang = -> (if Meteor.isClient then Session.get 'lang') ? u.defaultLang
u.updateFromForm = (form, obj = {}, splitTextOnLineBreak = true) ->
  # $('*[name]:not([type=radio])', form).add('*[name][type=radio]:checked', form).each ->
  (l=$('*[name]:not(:radio)', form).add('*[name]:radio:checked', form)).each ->
    node = $ @
    name = node.attr 'name'
    # logr name
    type = node.attr 'type'
    return false unless (value = node.val())?
    isText = (node.prop('tagName') is 'TEXTAREA')
    split = _.toBoolean(node.data('split') ? (splitTextOnLineBreak and isText)) # set data-split=true to split autmatically or false to avoid splitting
    uniq = _.toBoolean(node.data('remove-duplicates') ? false) # remove duplicates from array, thus, works only with split rendering true
    trim = _.toBoolean(node.data('trim') ? true) # default true, remove blank lines in arrays or white space from beginning and end of strings
    parse = _.toBoolean(node.data('parse') ? true) # default true, remove blank lines in arrays or white space from beginning and end of strings

    # conversions
    if split or _.isArray obj[name]
      value = value?.split "\n"
      if trim then value = _.without value, '%20', '', ' '
      if uniq then value = _.uniq value
    if _.isString value
      value = _.trim value if trim
      # logmr typeof value, value
      if parse
        if value.toLowerCase() in ['yes', 'true', 'on'] then value = true
        else if value.toLowerCase() in ['no', 'false', 'off'] then value = false
        else if _.isNumber(number = parseFloat value) and not _.isNaN number then value = number
      if (type?.toLowerCase?() is 'checkbox') and (not node.is(':checked'))
        value = (if _.isBoolean value then false else null)

    #logm "u.updateFromForm: updating #{name}=#{obj[name]} isText=#{isText}; split=#{split}; trim=#{trim}; parse=#{parse}; uniq=#{uniq} to #{value}", value;
    obj[name] = value
    return true # otherwise, if value is FALSE, jQuery will break the loop... :O#
  #logmr 'u.updateFromForm updated obj', obj
  obj
u.setChecked = (form, obj, silent = false) ->
  # make sure all inputs are initialized correctly - will not trigger change event
  for own attribute, value of logmr 'u.setChecked: obj', obj
    logr obj
    log "#{attribute}->#{value}"
    #$('[name="'+attribute+'"]:radio', form).each -> @checked = $(this).val() == value; true
    $('[name="'+attribute+'"][value="'+value+'"]:radio', form)[0]?.checked = true
    $('[name="'+attribute+'"]:checkbox', form).each ->
      logr @checked = asBoolean (logr value), $(logr this).val() is value; true
  unless silent then for attribute, value of obj
    $('[name="'+attribute+'"][value="'+value+'"]:radio', form).add('[name="'+attribute+'"]:checkbox', form).each ->
      $(this).change(); true
u.later = @later = (time, method) ->
  if _.isFunction time then [time, method] = [1, time]
  setTimeout method, time
# u.shorten = (string, maxLength) -> if string?.length > maxLength then string.substr(0, maxLength-3)+'...' else string
# u.shorten = (string, maxLength) -> _s.prune string, maxLength # shorten at the end
# padding in the middle, e.g. "Some rather extra...long string";
# test: s='Some rather extra super duper long string'; l=39; console.log(s); console.log(_s.pad('',l,'x')); u.shorten(s, l)
u.shorten = (string, maxLength, middle=true, glue='...') ->
  if (_.isNumber string) and ((_.isEmpty maxLength) or (_.isString maxLength) ) then [string, maxLength] = [maxLength, string]
  if not string? or string.length <= maxLength then string
  else
    if middle or not _s.contains string, ' '
      l0 = Math.floor maxLength*.55; l1 = maxLength - l0
      first = _s.prune string, l0, ''
      second = _s.reverse _s.prune (_s.reverse string), l1, ''
      if (result = "#{first}#{glue}#{second}").length > string.length then string else result # edge cases
    else _s.prune string, maxLength, glue # shorten at the end

u.toFixed = (number, decimalPlaces) ->
  parseFloat new Number(number).toFixed decimalPlaces
u.getValue = (object, path) -> if path? and object?
  if _.isString path then path = path.split('.').reverse()
  if path.length > 1 then u.getValue object[path.pop()], path
  else object[path[0]]
u.getValues = (path, objects...) ->
  (u.getValue object, path for object in _.flatten objects)


u.session = (key, value) ->
  if value?
    Session.set key, value
    value
  else Session.get key
u.sessionToggle = (key, initial = false) ->
  u.session key, not ((u.session key) ? not initial)


u.findAll = u.regex = u.extractAll = (exp, string) ->
  if _.isString exp then exp = new RegExp exp
  (r[1..] while (r = exp.exec string)?)

### locations #########################################################################################################
# location structure:
# label, lat, lng, distance (optional)
# Berlin is about 50, 10; lat==y, lng==x; lng > 0 east of London, lng < 0 west of London; lat at north pole = 90°

_.extend u.l,
  minRadius: 1000 # 1km
  defaultRadius: 10000 # 10km
  maxRadius: 1500000 # 1500km
  maxCloseByRadius: 20000 # 20km

  trim: (location) -> if location?
    location.lat = u.toFixed location.lat, 6
    location.lng = u.toFixed location.lng, 6
    location

  serialize: (location) ->
    if not location? or location is false then '_'
    else
      #trim = (value) -> value.toPrecision 6
      sanitize = (label) -> u.removeAll label, '/' , '\\', ':', '?'
      if _.isString location then sanitize location
      else
        location = @trim location
        #"#{sanitize location.label};#{trim location.lat},#{trim location.lng},#{location.distance}"
        "#{sanitize location.label};#{location.lat},#{location.lng},#{location.distance}"

  getCurrentLocation: -> Session.get 'u_geo-location'

  deserialize: (string) ->
    if string? and string isnt '_'
      s = string.split ';'
      if s.length != 2 then return logm "u.l.deserialize #{string}: invalid location", null
      c = s[1].split ','
      if c.length < 2 then return logm "u.l.deserialize #{string}: invalid location (at least lat,lng required)" , null
      # location =
        # label: s[0]
        # northEast: [parseFloat(c[0]), parseFloat(c[1])]
        # southWest: [parseFloat(c[2]), parseFloat(c[3])]
      u.l.create s[0], c[0], c[1], c[2]

  #createLocationIndex: (object, propertyName) ->
    #l = object[propertyName]; l.distance ?= u.l.defaultRadius
    #object["#{propertyName}Index"] = type: 'Point', coordinates: [l.lng ? 0, l.lat ? 0]
    #object["#{propertyName}Index"] = if (l = object[propertyName])?
      #type: 'Point', coordinates: [l.lng ? 0, l.lat ? 0]
    #else null

  equals: (l1, l2) ->	(l1 is l2) or ((u.l.distanceInMeters l1, l2) < 100) # NaN < 100 is false

  createBoundingBox: (lat, lng, distance, createNeSwBox=false) ->
    if lat?.lat? then [lat, lng, distance, createNeSwBox] = [lat.lat, lat.lng, lat.distance, lng ? false]
    lat = parseFloat lat
    lng = parseFloat lng
    distance = parseFloat distance
    northEast = u.l.moveInDirection lat, lng, distance, 45
    southWest = u.l.moveInDirection lat, lng, distance, 225
    #logm "u.l.createBoundingBox: lat=#{lat}; lng=#{lng}, distance=#{distance}; createNeSwBox=#{createNeSwBox}",
    if createNeSwBox then [[northEast[0], northEast[1]], [southWest[0], southWest[1]]] # needed for leaflet
    else [northEast[0], northEast[1], southWest[0], southWest[1]]

  getCenter: (locationOrBb) ->
    if locationOrBb.lat? and locationOrBb.lng? then [locationOrBb.lat, locationOrBb.lng]
    else
      if locationOrBb.northEast? and locationOrBb.southWest? then locationOrBb = [locationOrBb.northEast, locationOrBb.southWest]
      bb = _.flatten locationOrBb
      [(parseFloat(bb[0]) + parseFloat(bb[2]))/2, (parseFloat(bb[1]) + parseFloat(bb[3]))/2]

  # required coordinates order: lat north, lng east, lat south, lng west
  create: (label, lat, lng, distance) ->
    # example: "northEast":[7.4538509,51.52361699999999],"southWest":[7.42438,51.5084641]
    location =
      lat: parseFloat lat
      lng: parseFloat lng
      distance: parseFloat distance
      label: label

  # distance in meters!
  createFromPoint: (lat, lng, distance=u.l.defaultRadius, zoom=8, callback) ->
    if not callback?
      if _.isFunction distance then [callback, distance] = [distance, u.l.defaultRadius]
      else if _.isFunction zoom then [callback, zoom] = [zoom, 8]
    log "u.l.createFromPoint: lat=#{lat}; lng=#{lng}; distance=#{distance}; zoom=#{zoom}"
    location = logm 'u.l.createFromPoint: location', u.l.create '<picked from map>', lat, lng, distance
    u.l.addName location, zoom, callback

  createFromGeonamesData: (data) ->
    bb = data?.bbox ? {}
    label = (_.find data.alternateNames, (name) -> name.lang is u.getLang())?.name ? data.name
    if (country = data?.countryName)? and label.indexOf country < 0 then label = "#{label}, #{country}"
    distance = (u.l.distanceInMeters bb.north, bb.east, bb.south, bb.west)/2
    l = u.l.create label, data.lat, data.lng, distance
    # l.tokens = u.removeAll(label, ',', ';').split(' ')
    logm 'u.l.createFromGeonamesData', l

  createFromGoogle: (data) ->
    # label: result.formatted_address
    # result?.geometry?.location?.lat, result?.geometry?.location?.lng
    # result?.geometry?.bounds?.northeast?.lat, result?.geometry?.bounds?.northeast?.lng,
    # result?.geometry?.bounds?.southwest?.lat, result?.geometry?.bounds?.southwest?.lng
    g = result?.geometry; b = g?.bounds
    distance = (u.l.distanceInMeters b?.northeast?.lat, b?.northeast?.lng, b?.southwest?.lat, b?.southwest?.lng)/2
    l = u.l.create result.formatted_address, g?.location?.lat, g?.location?.lng, distance
    # l.tokens = u.removeAll(l.label, ',', ';').split(' ')
    logm 'u.l.createFromGoogleData', l

  createFromOsmData: (data) ->
    # boundingbox: ["15.7807521820068", "15.7807531356812", "44.1298446655273", "44.1298484802246"]
    # lat: "15.780753", lon: "44.129847"
    # -> bb = [lat_south, lat_north, lng_west, lng_east]
    # required: lat north, lng east, lat south, lng west
    # bb = if (bb = data.boundingbox)? then [bb[3], bb[1], bb[2], bb[0]] else u.l.createBoundingBox data.lat, data.lon, u.l.minRadius
    #distance = if (bb = data.boundingbox)? then (u.l.distanceInMeters bb[1], bb[3], bb[0], bb[2])/2 else u.l.defaultRadius
    if (bb = data.boundingbox)?
      bb = parseFloatOr bb, 0
      data.lat = (bb[1]+bb[0])/2; data.lon = (bb[3]+bb[2])/2 # lat/lng is ofter far off the center, e.g. in Greece
      distance = (u.l.distanceInMeters bb[1], bb[3], bb[0], bb[2])/2.5 # with 2 the radius was too much somehow for Greece
    else distance = u.l.defaultRadius
    l = u.l.create data.display_name, data.lat, data.lon, (if distance < u.l.minRadius then u.l.defaultRadius else distance)
    # l.tokens = u.removeAll(l.label, ',', ';')?.split(' ') ? []
    l # logm 'u.l.createFromOsmData', l

  createFromJavascriptApi: (data, callback) ->
    # Geoposition {timestamp: 1385572916765, coords: {
      # accuracy: 34
      # altitude: null
      # altitudeAccuracy: null
      # heading: null
      # latitude: 37.9628883
      # longitude: 23.754608299999997
      # speed: null
    # }}
    distance = Math.max data?.coords?.accuracy, u.l.defaultRadius
    l = u.l.create '<current location>', data?.coords?.latitude, data?.coords?.longitude, distance
    # l.tokens = u.removeAll(l.label, ',', '<', '>', ';').split(' ')
    if callback?
      # u.x.osm.reverse data?.coords?.latitude, data?.coords?.longitude, (data) ->
        # if data?
          # osmLocation = u.l.createFromOsmData data # does never contain a bounding box unfortunately
          # l.label = osmLocation.label
          # l.tokens = osmLocation.tokens
        # callback l
      u.l.addName l, callback
    logm 'u.l.createFromJavascriptApi', l

  addName: (location, zoom=8, callback) ->
    if _.isFunction zoom then [zoom, callback] = [8, zoom]
    check callback, Function
    # match leaflet.zoom with OSM zoom, usually too detailed
    zoom = Math.max 0, zoom-(if zoom > 7 then 3 else 2)
    # 6..9 give very funny results for Berlin
    # http://nominatim.openstreetmap.org/reverse?format=json&lat=52.546713&lon=13.455849&zoom=8&addressdetails=0
    if 5 < zoom < 8 then zoom = 5
    if 7 < zoom < 10 then zoom = 10
    u.x.osm.reverse location.lat, location.lng, zoom, (data) ->
      if data?
        osmLocation = u.l.createFromOsmData data
        location.label = u.l.sanitizeLabel osmLocation.label
      callback logmr 'u.l.addName: enhanced location', location

  labelBlackList: ['Central section of ', /,([^,]*)Prefecture/, /Municipality of ([^,]*), /, /, European Union$/]
  labelReplaceMap:
    'European Union, .*$': 'European Union' # avoid wierd 'Europ...., Germany'
  sanitizeLabel: (label) ->
    if isEmpty label then 'unknown location'
    else _s.trim u.replaceAll (u.removeAll label, u.l.labelBlackList), u.l.labelReplaceMap
  sanitize: (location) -> u.withIf location, ->
    @lat = (@?.lat ? 0) % 180
    @lng = (@?.lng ? 0) % 90
    @label = u.l.sanitizeLabel @?.label ? ''
    @

  # returns the {@link GeoPoint} that is in the given direction at the following
  # radiusInKm of the given point.<br>
  # Uses Vincenty's formula and the WGS84 ellipsoid.
  #
  # Copyright 2010, Silvio Heuberger @ IFS www.ifs.hsr.ch
  #
  # directionInDegrees must be within 0 and 360, south=0, east=90, north=180, west=270
  moveInDirection: (lat, lng, distanceInMeters=100, directionInDegrees=0) ->

    if directionInDegrees < 0 or directionInDegrees > 360 then throw new Error "direction must be in (0,360) but was #{directionInDegrees}"

    DEG_TO_RAD = 0.0174532925

    a = 6378137
    b = 6356752.3142
    f = 1/298.257223563 # WGS-84

    # ellipsiod
    alpha1 = directionInDegrees * DEG_TO_RAD
    sinAlpha1 = Math.sin(alpha1)
    cosAlpha1 = Math.cos(alpha1)

    tanU1 = (1 - f) * Math.tan(lat * DEG_TO_RAD)
    cosU1 = 1 / Math.sqrt(1 + tanU1 * tanU1)
    sinU1 = tanU1 * cosU1
    sigma1 = Math.atan2 tanU1, cosAlpha1
    sinAlpha = cosU1 * sinAlpha1
    cosSqAlpha = 1 - sinAlpha * sinAlpha
    uSq = cosSqAlpha * (a * a - b * b) / (b * b)
    A = 1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)))
    B = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)))

    sinSigma = 0
    cosSigma = 0
    cos2SigmaM = 0
    sigma = distanceInMeters / (b * A)
    sigmaP = 2 * Math.PI
    while Math.abs(sigma - sigmaP) > 1e-12
      cos2SigmaM = Math.cos(2 * sigma1 + sigma)
      sinSigma = Math.sin sigma
      cosSigma = Math.cos sigma
      deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)))
      sigmaP = sigma;
      sigma = distanceInMeters / (b * A) + deltaSigma

    tmp = sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1
    lat2 = Math.atan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1, (1 - f) * Math.sqrt(sinAlpha * sinAlpha + tmp * tmp))
    lambda = Math.atan2(sinSigma * sinAlpha1, cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1)
    C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
    L = lambda - (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))

    newLat = lat2 / DEG_TO_RAD;
    newLon = lng + L / DEG_TO_RAD;

    newLon = if newLon > 180.0 then 360.0 - newLon else newLon
    newLon = if newLon < -180.0 then 360.0 + newLon else newLon

    [newLat, newLon]

  # Copyright 2010, Silvio Heuberger @ IFS www.ifs.hsr.ch
  distanceInMeters: (lat1, lng1, lat2, lng2) ->
    if _.isFunction lat1?.getNorth
      lng1 = lat1.getWest()
      lat2 = lat1.getSouth()
      lng2 = lat1.getEast()
      lat1 = lat1.getNorth()
    else if not lat2? and not lng2? and _.isArray(lat1) and _.isArray(lng1)
      lat2 = lng1[0]; lng2 = lng1[1]; lng1 = lat1[1]; lat1 = lat1[0]

    DEG_TO_RAD = 0.0174532925; EPSILON = 1e-12;
    a = 6378137; b = 6356752.3142; f = 1 / 298.257223563; # WGS-84

    # ellipsiod
    L = (lng2 - lng1) * DEG_TO_RAD;
    U1 = Math.atan((1 - f) * Math.tan(lat1 * DEG_TO_RAD));
    U2 = Math.atan((1 - f) * Math.tan(lat2 * DEG_TO_RAD));
    sinU1 = Math.sin U1; cosU1 = Math.cos U1
    sinU2 = Math.sin U2; cosU2 = Math.cos U2

    cosSqAlpha = sinSigma = cos2SigmaM = cosSigma = sigma = 0

    lambda = L; lambdaP = 0; iterLimit = 20;
    loop
      sinLambda = Math.sin lambda; cosLambda = Math.cos lambda
      sinSigma = Math.sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) + (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) * (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda))
      if sinSigma == 0 then return 0 # coincident points
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda
      sigma = Math.atan2 sinSigma, cosSigma
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma
      cosSqAlpha = 1 - sinAlpha * sinAlpha
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha
      if _.isNaN cos2SigmaM then cos2SigmaM = 0; # equatorial line: cosSqAlpha=0
      C = f / 16 * cosSqAlpha * (4 + f * (4 - 3 * cosSqAlpha))
      lambdaP = lambda
      lambda = L + (1 - C) * f * sinAlpha * (sigma + C * sinSigma * (cos2SigmaM + C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)))
      break unless Math.abs(lambda - lambdaP) > EPSILON and --iterLimit > 0

    if iterLimit == 0 then return Number.NaN

    uSquared = cosSqAlpha * (a * a - b * b) / (b * b)
    A = 1 + uSquared / 16384 * (4096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)))
    B = uSquared / 1024 * (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)))
    deltaSigma = B * sinSigma * (cos2SigmaM + B / 4 * (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) - B / 6 * cos2SigmaM * (-3 + 4 * sinSigma * sinSigma) * (-3 + 4 * cos2SigmaM * cos2SigmaM)))
    s = b * A * (sigma - deltaSigma)

    s


### external services #################################################################################################

_.extend u.x,
  # result: { areacode: "", city: "", country_code: "DE", country_name: "Germany", ip: "78.50.200.10", latitude: 51, longitude: 9, metro_code: "", region_code: "", region_name: "", zipcode: "" }
  geoip: (callback) ->
    try
      $.ajax "http://freegeoip.net/json/",
        success: (data) -> callback logmr 'u.x.geoip: data', data
        error: (data) ->
          logmr 'u.x.geoip: error', data
          callback false
    catch e
      loge e
      callback false

  # parameters: limit=1, addressdetails=0/1
  # q for query, plain text or *NOT BOTH* street=<housenumber> <streetname>, city=<city>, county=<county>, state=<state>, country=<country>, postalcode=<postalcode>
  # result for "Germany" [{"place_id":"97944985","licence":"Data \u00a9 OpenStreetMap contributors, ODbL 1.0. http:\/\/www.openstreetmap.org\/copyright","osm_type":"relation","osm_id":"51477",
  #   "boundingbox":["47.2701110839844","55.1175498962402","5.86631488800049","15.0419321060181"], -> [lat-min, lat-max, lng-min, lng-max]
  #   "lat":"51.0834196","lon":"10.4234469","display_name":"Germany, European Union","class":"boundary","type":"administrative","importance":1.0306411269346,"icon":"http:\/\/nominatim.openstreetmap.org\/images\/mapicons\/poi_boundary_administrative.p.20.png"}, ... ]
  osm:
    _getFirstLocation: (results, boundingBoxRequired = true) ->
      for data in (asArray results)
        if (not boundingBoxRequired or data?.boundingbox?) and data?.display_name? then return u.l.createFromOsmData data

    find: (parameters, callback) ->
      parameters = (for p,v of parameters
        "#{p}=#{v}").join "&"
      $.ajax (logmr 'u.x.osm: request URL', "http://nominatim.openstreetmap.org/search?format=json&#{parameters}"),
        success: (data) -> callback(logmr 'u.x.osm: data', data)

    reverse: (lat, lng, zoom=8, callback) ->
      if _.isFunction zoom then [zoom, callback] = [8, zoom]
      url = "http://nominatim.openstreetmap.org/reverse?format=json&lat=#{lat}&lon=#{lng}&zoom=#{zoom}&addressdetails=0"
      $.ajax (logmr 'u.x.osm.reverse: request URL', url),
        success: (data) -> callback logmr 'u.x.osm.reverse: data', data
        error: (x, s, e) ->
          logmr "u.x.osm.reverse: status=#{s}; failed", e
          callback false

  getLocation: (query, callback) ->
    u.x.osm.find { q: query, limit: 5, addressdetails: 0 }, (data) ->
      # if (data = u.x.osm._getFirstLocation(data))? then callback u.l.createFromOsmData data
      callback u.x.osm._getFirstLocation data

  currentLocation: (callback, useBrowserLocation = true) ->
    if Modernizr.geolocation and useBrowserLocation
      # PositionError {message: "User denied Geolocation", code: 1, PERMISSION_DENIED: 1, POSITION_UNAVAILABLE: 2, TIMEOUT: 3}
      navigator.geolocation.getCurrentPosition (geoData) ->
        u.l.createFromJavascriptApi((logmr 'u.x.currentLocation: js API data', geoData), callback) # callback twice: first: returned raw data, second: with label
      , ((error) -> loge error; u.x.currentLocation callback, false)
    else
      u.x.geoip (data) ->
        if data?.country_name?
          u.x.osm.find { country: data.country_name, limit: 1, addressdetails: 0 }, (data) ->
            # convert osm data to location obj
            #if (data = data?[0])? and data?.boundingbox? and data?.display_name?
            if (data = data?[0])? and data?.display_name?
              # callback u.l.create data.display_name, data.boundingbox, true
              callback u.l.createFromOsmData data
            else callback false
        else callback false
