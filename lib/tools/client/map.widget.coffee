log "mw.init: client=#{Meteor.isClient}"
Template.mapWidget.created = ->
	log 'mw.created...'
Template.mapWidget.rendered = ->
	logmr 'mw.rendered: @', @
	if @controller? then @controller.setData @data
	else @controller = new MapController @firstNode, @data

class MapController
	constructor: (@contrainer, @data) ->
		@m = {}
		@wait = 100
		@minDistance = 1000
		@maxDistance = 500000
		log 'mw.c...'
		if @data.autoInit ? true then @setData @data

	setData: (@data) -> @init =>
		logmr 'mw.c.setData', @data
		@s = @data.show ? all: true
		# TODO initv2: instead of showing and hiding, remove and add components in init method
		@c.map.toggle      @s.all ? @s.map      ? true
		@c.search.toggle   @s.all ? @s.search   ? true
		@c.distance.toggle @s.all ? @s.distance ? true

		@container.attr 'style', @data.style?.container
		@c.map.attr 'style', @data.style?.mapContainer
		@d.map.attr 'style', @data.style?.map
		if @s.marker ? true then @m.marker.addTo @m.map
		else @m.map.removeLayer @m.marker
		@setLocation()

	setDistance: (d) ->
		d ?= if (l = @data.location)? then Math.round (u.l.distanceInMeters l.northEast, l.southWest)/2 else @minDistance
		@d.distance.val Math.round d/1000
	getDistance: -> Math.min @maxDistance, 1000*parseFloat @d.distance.val()

	setLocation: (location = @data.location, moveInView = false, calculateDistance = true) ->
		@data.location = location
		if calculateDistance then @setDistance()
		@m.marker.setLatLng location?.coordinates ? [0,0]
		@updateRectangle moveInView
		@updateSearch()
		@notify()
	moveLocation: (latLng, moveInView = false) ->
		if _.isBoolean latLng then [latLng, moveInView] = [undefined, latLng]
		if latLng? then @m.marker.setLatLng latLng
		else latLng = @m.marker.getLatLng()
		@updateRectangle moveInView
		u.l.createFromPoint latLng.lat, latLng.lng, @getDistance(), (location) =>
			@setLocation location, false, false

	updateRectangle: (moveInView = false) ->
		coordinates = @m.marker.getLatLng()
		distance = @getDistance()
		logm "mw.c.updateRect dist=#{distance}; coordinates", coordinates
		@m.rect.setBounds bounds = unless @data.area then [[0,0],[0,0]] else u.l.createBoundingBox(coordinates.lat, coordinates.lng, distance, true)
		logm 'mw.c.updateRect bounds ', bounds
		unless @m.map.getBounds().contains bounds
			logm 'mw.c.updateRect: auto panning; also zoom', moveInView
			boundsMuchBigger = not @m.map.getBounds().pad(2).contains(bounds)
			if moveInView or boundsMuchBigger then @m.map.fitBounds(bounds)
			else @m.map.panTo u.l.getCenter bounds

	updateSearch: _.debounce (->
		# u.w.setTypeaheadQuery @d.search, (@data.location?.label ? '')), 300
		@m.search.setValue (@data.location?.label ? '')), 300

	plotMarkers: ->
		if @m.markers?.length
			@m.map.removeLayer m for m in @m.markers
		@m.markers = unless @data.markers?.length then []
		else @plotMarker index, def for def, index in @data.markers
	plotMarker: (index, def) ->
		markerHtml = '<i class="fa fa-map-marker fa-stack-2x"></i><i class="fa fa-circle fa-stack-1x"></i><span>'+(index+1)+'</span>'
		icon = L.divIcon
			className:  'result-map-marker'+(if index>8 then ' more-than-one-digit' else '')
			iconAnchor: [8.666, 29]
			html:       markerHtml
		($ icon).data 'placement', 'left'
		marker = L.marker def.location.coordinates,
			icon: icon
			title: def.label
		u.events marker, def.events
		marker.addTo map
		marker

	distanceChanged: -> @moveLocation true
	mapClicked: (event) ->
		n=(b=@m.map.getBounds()).getNorth();s=b.getSouth();w=b.getWest();e=b.getEast()
		width = u.l.distanceInMeters n, e, n, w
		height = u.l.distanceInMeters n, e, s, e
		@setDistance .45 * Math.min width, height
		@moveLocation event.latlng
	geoLocationClicked: ->
		@d.geoLocation.addClass 'active'
		u.x.currentLocation (location) =>
			@setLocation location, true
			@d.geoLocation.removeClass 'active'
	notify: _.debounce (-> @data.onChange @data.location, @getDistance()), 300

	init: (done) ->
		log 'mw.c.init...'
		# TODO initv2: wait if map is needed only
		unless L?
			log 'mw.c.init: waiting to load...'
			later (@wait*=2), => @init(done)
			return
		@doInit()
		logmr 'mw.c.init: done', @
		done()

	doInit: _.once ->
		# TODO initv2: remove once; instead, add and remove components as configured
		log 'mw.c.doInit...'
		# get references
		@c = # conainters
			map: $ '.map-container', @container
			search: $ '.search-container', @container
			distance: $ '.distance-container', @container
		@d = # data object
			map: $ '.map', @c.map
			search: $ '.search', @c.search
			geoLocation: $ '.geo-location', @c.search
			distance: $ '.distance', @c.distance
		# init leaflet map and layers
		# logmr 'mw.c.doInit: search', @m.search = u.w.createLocationTypeahead @d.search, @data.location?.label, ((event, location) => @setLocation location, true), => @data.location
		logmr 'mw.c.doInit: search', @m.search = u.w.createLocationTypeahead2 @d.search, ((event, location) => @setLocation location, true), => @data.location
		unless @d.map?.length then @d.map = ($ '<div class="map"></div>').attachTo @c.map
		unless (@d.map.data 'leafletMap')?
			@m.map = map = L.map @d.map[0],
				center: @data.location?.coordinates ? [0,0]
				zoom: 13
			# add an OpenStreetMap tile layer
			L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', { attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'}).addTo map
			@d.map.data 'leafletMap', map
			@m.rect = (L.rectangle [[0,0],[0,0]], { color: u.pickLocationRectColor, weight: 1 }).addTo map
			@m.marker = L.marker [0, 0], title: 'current location'

		# hook up event handlers
		@d.distance.on 'change', => @distanceChanged()
		@m.map.on 'click', (e) => @mapClicked e
		@d.geoLocation.on 'click', => @geoLocationClicked()

