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
#	'chop': (array, partSize) ->
#		array = @clone array
#		(array.splice 0, partSize until array.length <= 0)
#	'split': (array, pieces) ->
#		@chop array, Math.ceil array.length/pieces
#	'pushAll': (array, all) ->
#		if all?.length > 0 then array.push obj for obj in all
#		array

u.addCommonMethods = (object, collection, showRoute, getLabel) -> _.extend object,
	get: (id) -> if _.isString id then collection.findOne { _id: id } else id
	findAll: (ids) ->
		try
			if collection.findAll? then collection.findAll ids
			else Meteor.Collection.prototype.findAll.apply collection, [ids]
		catch e
			loge e
	getAll: (ids) -> @findAll(ids)?.fetch()
	label: (obj) -> getLabel obj
	url: (obj) -> Router.url showRoute, @get obj
	link: (obj) ->
		obj = @get obj
		"<a href=\"#{@url obj}\">#{@label obj}</a>"

### logging ###########################################################################################################

u._loggingEnabled = -> Session?.get?('loggingEnabled') ? (Meteor?.isServer or window?.location?.href?.indexOf?('localhost')>=0)
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
u.logr = @logr = (obj) =>
	if not u._loggingEnabled() then return
	try
		console.log obj
		if ("" + obj).toLowerCase().indexOf("error") >= 0 then console.trace()
	catch error
		console.log "error in logr:"
		console.log error.stack
	obj
u.logm = @logm = (msg, obj) =>
	try
		u.logr u._getTimeStamp()+msg+": "+JSON.stringify obj
	catch error
		console.log "error in logm: msg=#{msg}"
		console.log error.stack
	obj
u.logmr = @logmr = (msg, obj) =>
	try
		# console.log "#{msg}: #{obj}"
		u.logr u._getTimeStamp()+"#{msg}: "
		u.logr obj
	catch error
		console.log "error in logmr: msg=#{msg}"
		console.log error.stack
	obj
u.logmkv = @logmkv = (msg, obj) =>
	try
		u.logr u._getTimeStamp()+"#{msg}: " + (for k,v of obj
			if typeof v == "function" then "#{k}=f(...)\n" else "#{k}=#{v}\n")
	catch error
		console.log "error in logmkv: msg=#{msg}"
		console.log error.stack
	obj
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
@parseIntOr = (value, otherwise) -> unlessNaN (parseInt value), otherwise
@parseFloatOr = (value, otherwise) -> unlessNaN (parseFloat value), otherwise
@unlessNaN = (value, otherwise) -> unless _.isNaN value then value else otherwise
@doAndReturnIf = (data, fn) -> doAndReturn data, -> fn data if data?
@doAndReturn = (data, fn) ->
	fn data
	data
@maybe = (data, condition, fn) ->
	if _.isFunction condition then condition = condition data
	if condition then fn data else data

@maybeFilter = (data, condition, filter) ->
	if data?
		if _.isFunction condition then condition = condition data
		if condition then data = _.filter data, filter
	data

@transform = (data, fn) ->
	results = if _.isArray then [] else {}
	if data?
		for item,key in data
			if (transformed = fn item)? then results[key] = transformed
	results

u.createObject = @createObject = ->
	object = {}
	for o,i in arguments
		if i%2==1 and (key = arguments[i-1])? then object[key] = o
	object
u.asArray = @asArray = (something) ->
	if _.isArray something then something else [something]
u.notEmpty = @notEmpty = (stringOrArray, toBeRemoved...) ->
	if (o = stringOrArray)?
		if _.isString o then o = $.trim(o)
		if toBeRemoved? and toBeRemoved.length > 0 then o = u.removeAll o, _.flatten(toBeRemoved)
		if o.length > 0 then o else null
	else null
u.removeAll = (stringOrArray, toBeRemoved...) ->
	unless stringOrArray?.length then return stringOrArray
	toBeRemoved = _.flatten toBeRemoved
	if _.isArray stringOrArray then _.without stringOrArray, toBeRemoved
	else for remove in toBeRemoved
		# logm "u.removeAll #{stringOrArray}", remove
		stringOrArray = stringOrArray.replace remove, ''
	return stringOrArray
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
			if (type?.toLowerCase?() is 'checkbox') and (not node.attr('checked')?)
				value = (if _.isBoolean value then false else null)

		logm "u.updateFromForm: updating #{name}=#{obj[name]} isText=#{isText}; split=#{split}; trim=#{trim}; parse=#{parse}; uniq=#{uniq} to #{value}", value;
		obj[name] = value
		return true # otherwise, if value is FALSE, jQuery will break the loop... :O#
	logmr 'u.updateFromForm updated obj', obj
u.setChecked = (form, obj) ->
	for attribute, value of obj
		$('*[name="'+attribute+'"]:radio').each -> $(this).attr 'checked', $(this).val() == value
		$('*[name="'+attribute+'"]:checkbox').each -> $(this).attr 'checked', value or $(this).val() == value
u.later = @later = (time, method) ->
	if _.isFunction time then [time, method] = [1, time]
	setTimeout method, time
# u.shorten = (string, maxLength) -> if string?.length > maxLength then string.substr(0, maxLength-3)+'...' else string
u.shorten = (string, maxLength) -> _s.prune string, maxLength
u.session = (key, value) ->
	if value?
		Session.set key, value
		value
	else Session.get key

u.findAll = u.regex = u.extractAll = (exp, string) ->
	if _.isString exp then exp = new RegExp exp
	(r[1..] while (r = exp.exec string)?)

### locations #########################################################################################################
# structure:
# label
# coordinates[lat, lon] -> Berlin is about 50, 10; lat==y, lon==x; lon > 0 east of London, lon < 0 west of London; lat at north pole = 90°
# northEast[lat, lon]   -> around Berlin: southWest < northEast
# southWest[lat, lon]

_.extend u.l,
	minRadius: 1000 # 1km
	maxRadius: 500000 # 500km
	serialize: (location) ->
		if not location? then '_' else (if typeof location == 'String' then location
		# else location.label+';'+location.northEast[0]+','+location.northEast[1]+','+location.southWest[0]+','+location.southWest[1])
		else "#{location.label};#{location.northEast[0]},#{location.northEast[1]},#{location.southWest[0]},#{location.southWest[1]}")

	getCurrentLocation: -> Session.get 'u_geo-location'

	deserialize: (string) ->
		if string? and string isnt '_'
			s = string.split ';'
			if s.length != 2 then return logm "u.l.deserialize #{string}: invalid location", null
			c = s[1].split ','
			if c.length != 4 then return logm "u.l.deserialize #{string}: invalid location (four coordinates required)" , null
			# location =
				# label: s[0]
				# northEast: [parseFloat(c[0]), parseFloat(c[1])]
				# southWest: [parseFloat(c[2]), parseFloat(c[3])]
			u.l.create s[0], c

	createBoundingBox: (lat, lng, distance, createNeSwBox=false) ->
		lat = parseFloat lat
		lng = parseFloat lng
		distance = parseFloat distance
		# [lat+.01, lng+.01, lat-.01, lng-.01]
		# TODO_ caculate bounding box using distance
		northEast = u.l.moveInDirection lat, lng, distance, 45
		southWest = u.l.moveInDirection lat, lng, distance, 225
		logm "u.l.createBoundingBox: lat=#{lat}; lng=#{lng}, distance=#{distance}; createNeSwBox=#{createNeSwBox}",
		if createNeSwBox then [[northEast[0], northEast[1]], [southWest[0], southWest[1]]] # needed for leaflet
		else [northEast[0], northEast[1], southWest[0], southWest[1]]

	getCenter: (locationOrBb) ->
		if locationOrBb.northEast? and locationOrBb.southWest? then locationOrBb = [boundingBox.northEast, boundingBox.southWest]
		bb = _.flatten locationOrBb
		return [(parseFloat(bb[0]) + parseFloat(bb[2]))/2, (parseFloat(bb[1]) + parseFloat(bb[3]))/2]

	# required coordinates order: lat north, lng east, lat south, lng west
	create: (label, coordinates, lat, lng) ->
		# example: "northEast":[7.4538509,51.52361699999999],"southWest":[7.42438,51.5084641]
		location =
			northEast: [parseFloat(coordinates[0]), parseFloat(coordinates[1])]
			southWest: [parseFloat(coordinates[2]), parseFloat(coordinates[3])]
		location.label = label
		# location.coordinates = if lat? and lng? then [parseFloat(lat), parseFloat(lng)] else [(location.northEast[0] + location.southWest[0])/2, (location.northEast[1] + location.southWest[1])/2]
		location.coordinates = if lat? and lng? then [parseFloat(lat), parseFloat(lng)] else u.l.getCenter coordinates
		location

	# distance in meters!
	createFromPoint: (lat, lng, distance=u.l.minRadius, callback) ->
		if not callback? and _.isFunction distance
			callback = distance
			distance = u.l.minRadius

		log "u.l.createFromPoint: lat=#{lat}; lng=#{lng}; distance=#{distance}"
		location = logm 'u.l.createFromPoint: location', u.l.create '<picked from map>', u.l.createBoundingBox(lat, lng, distance), lat, lng
		u.l.addName location, callback

	createFromGeonamesData: (data) ->
		bb = data?.bbox ? {}
		label = (_.find data.alternateNames, (name) -> name.lang is u.getLang())?.name ? data.name
		if (country = data?.countryName)? and label.indexOf country < 0 then label = "#{label}, #{country}"
		l = u.l.create label, [bb.north, bb.east, bb.south, bb.west], data.lat, data.lng
		l.tokens = u.removeAll(label, ',', ';').split(' ')
		logm 'u.l.createFromGeonamesData', l

	createFromGoogle: (data) ->
		# label: result.formatted_address
		# result?.geometry?.location?.lat, result?.geometry?.location?.lng
		# result?.geometry?.bounds?.northeast?.lat, result?.geometry?.bounds?.northeast?.lng,
		# result?.geometry?.bounds?.southwest?.lat, result?.geometry?.bounds?.southwest?.lng
		g = result?.geometry
		l = u.l.create result.formatted_address, [g?.bounds?.northeast?.lat, g?.bounds?.northeast?.lng, g?.bounds?.southwest?.lat, g?.bounds?.southwest?.lng], g?.location?.lat, g?.location?.lng
		l.tokens = u.removeAll(l.label, ',', ';').split(' ')
		logm 'u.l.createFromGoogleData', l

	createFromOsmData: (data) ->
		# boundingbox: ["15.7807521820068", "15.7807531356812", "44.1298446655273", "44.1298484802246"]
		# lat: "15.780753", lon: "44.129847"
		# -> bb = [lat_south, lat_north, lng_west, lng_east]
		# required: lat north, lng east, lat south, lng west
		# bb = if (bb = data.boundingbox)? then [bb[3], bb[1], bb[2], bb[0]] else u.l.createBoundingBox data.lat, data.lon, u.l.minRadius
		bb = if (bb = data.boundingbox)? then [bb[1], bb[3], bb[0], bb[2]] else u.l.createBoundingBox data.lat, data.lon, u.l.minRadius
		l = u.l.create data.display_name, bb, data.lat, data.lon
		l.tokens = u.removeAll(l.label, ',', ';')?.split(' ') ? []
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
		bb = u.l.createBoundingBox data?.coords?.latitude, data?.coords?.longitude, Math.max(data?.coords?.accuracy, u.l.minRadius)
		l = u.l.create '<current location>', bb, data?.coords?.latitude, data?.coords?.longitude
		l.tokens = u.removeAll(l.label, ',', '<', '>', ';').split(' ')
		if callback?
			# u.x.osm.reverse data?.coords?.latitude, data?.coords?.longitude, (data) ->
				# if data?
					# osmLocation = u.l.createFromOsmData data # does never contain a bounding box unfortunately
					# l.label = osmLocation.label
					# l.tokens = osmLocation.tokens
				# callback l
			u.l.addName l, callback
		logm 'u.l.createFromJavascriptApi', l

	addName: (location, callback) ->
		check callback, Function
		u.x.osm.reverse location.coordinates[0], location.coordinates[1], (data) ->
			if data?
				osmLocation = u.l.createFromOsmData data
				location.label = osmLocation.label
				location.tokens = osmLocation.tokens
			logr callback
			callback logmr 'u.l.addName: enhanced location', location

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
		if not lat2? and not lng2? and _.isArray(lat1) and _.isArray(lng1)
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

		reverse: (lat, lng, callback) ->
			url = "http://nominatim.openstreetmap.org/reverse?format=json&lat=#{lat}&lon=#{lng}"
			$.ajax (logmr 'u.x.osmReverse: request URL', url),
				success: (data) -> callback(logmr 'u.x.osm: data', data)

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
						if (data = data?[0])? and data?.boundingbox? and data?.display_name?
							# callback u.l.create data.display_name, data.boundingbox, true
							callback u.l.createFromOsmData data
						else callback false
				else callback false
