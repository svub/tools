Template.mapWidget.rendered = ->
  container = $ @find '.map-widget' # @firstNode
  unless _.isFunction d = @data then @data = -> d
  @controller = new MapController container, @data
  container.data 'mapController', @controller


class MapController
  constructor: (@container, @dataSource) ->
    @m = {}
    @wait = 100
    @minDistance = u.l.minRadius ? 1000
    @defaultDistance = u.l.defaultRadius ? 5000
    @maxDistance = u.l.maxRadius ? 500000
    @container = $ @container
    @doInit = _.once => @_doInit()
    if (d = @dataSource())?.autoInit ? true then @setData d
    Deps.autorun => @update()

  setData: (newData) -> unless EJSON.equals newData, @data then @data = newData; @ensureInit =>
    @doNotify = false
    logmr 'MapWidget.setData', @data
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
    @updateLocation()
    later =>
      @plotMarkers()
      later 50, => @doNotify = true

  setDistance: (d) ->
    d ?= @data.location?.distance ? @defaultDistance
    @d.distance.val Math.round (between d, @minDistance, @maxDistance)/1000
  getDistance: -> between (unlessNaN (1000*parseFloat @d.distance.val()), @minDistance), @minDistance, @maxDistance

  setLocation: (location = @data.location, moveInView = false, calculateDistance = true) ->
    @data.location = location
    @updateLocation moveInView, calculateDistance, true
  updateLocation: (moveInView = false, calculateDistance = true, notify = false) ->
    logmr 'MapWidget.updateLocation: location', @data.location
    unless (location = @data.location)?
      if @data.markers?.length and (b = L.latLngBounds (m.location for m in @data.markers))?
        logmr 'MapWidget.updateLocation: l from markers..., b', b
        logmr 'MapWidget.updateLocation: location', location = b.getCenter()
        bounds = [[b.getNorth(), b.getEast()], [b.getSouth(), b.getWest()]]
        logmr 'MapWidget.updateLocation: bounds', bounds
        @autoZoom true, bounds
      else
        @m.map.fitWorld()
      @updateArea false, false # hide area marker without location
    if calculateDistance then @setDistance()
    @m.marker.setLatLng location ? [0,0]
    if @data.location? then @updateArea moveInView
    @updateSearch()
    if notify then @notify()
  moveLocation: (latLng, moveInView = false) ->
    if _.isBoolean latLng then [latLng, moveInView] = [undefined, latLng]
    if latLng? then @m.marker.setLatLng latLng
    else latLng = @m.marker.getLatLng()
    @updateArea moveInView
    @enrichLocation latLng
  # changed throttle to debounce so that map.zoom is updated
  enrichLocation: debounce 100, (latLng = @m.marker.getLatLng()) ->
    u.l.createFromPoint latLng.lat, latLng.lng, @getDistance(), @m.map.getZoom(), (location) =>
      @setLocation location, false, false

  updateArea: (moveInView = false, area = @data.area) ->
    if area
      coordinates = @m.marker.getLatLng()
      distance = @getDistance()
      logm "MapWidget.updateArea moveInView=#{moveInView}; areaType=#{@data.areaType}; dist=#{distance}; coordinates", coordinates
      (if @data.areaType is 'rect' then @updateRectangle else @updateCircle).call @, coordinates, distance
      @autoZoom moveInView, coordinates, distance
    else
      @m.map.removeLayer @m.rect
      @m.map.removeLayer @m.circle
  updateRectangle: (coordinates, distance) ->
    @m.rect.setBounds bounds = u.l.createBoundingBox(coordinates.lat, coordinates.lng, distance, true)
    @m.rect.addTo @m.map

  updateCircle: (coordinates, distance) ->
    @m.circle.setLatLng coordinates
    @m.circle.setRadius distance
    @m.circle.addTo @m.map

  updateSize: -> # call when map does not fit container, e.g. after container resizing
    log '### meouw'
    @m.map._onResize()
    @m.map.panBy [0,1]
    @m.map.panBy [0,-1]

  updateSearch: debounce 300, ->
    # u.w.setTypeaheadQuery @d.search, (@data.location?.label ? '')), 300
    logmr 'MapWidget.updateSearch: l, m.search', @data.location, @m.search
    @m.search.setValue @data.location

  update: -> # force updating
      try @setData @dataSource()
      later => try @updateSize()

  # coordinates can be bounds array, too
  autoZoom: (zoom = false, coordinates = @m.marker.getLatLng(), distance = @getDistance()) ->
      logm 'MapWidget.autoZoom: coordinates', coordinates
      bounds = if (_.isArray coordinates) then coordinates
      else u.l.createBoundingBox coordinates.lat, coordinates.lng, distance*1.1, true
      if (mapBounds = @m.map.getBounds()).contains bounds # zoom in?
        if distance * 5 < u.l.distanceInMeters mapBounds # much smaller, zoom in
          try @m.map.fitBounds bounds
      else # zoom out?
        logm 'MapWidget.autoZoom: bounds', bounds
        boundsMuchBigger = not @m.map.getBounds().pad(2).contains bounds
        if zoom or boundsMuchBigger then @m.map.fitBounds bounds
        else @m.map.panTo coordinates

  plotMarkers: ->
    if @m.markers?.length
      @m.map.removeLayer m for m in _.flatten @m.markers
    @m.markers = unless @data.markers?.length then []
    else @plotMarker index, def for def, index in @data.markers
  plotMarker: (index, def) ->
    markerHtml = '<i class="fa fa-map-marker fa-stack-2x"></i><i class="fa fa-circle fa-stack-1x"></i><span>'+(index+1)+'</span>'
    icon = L.divIcon
      className:  'result-map-marker'+(if index>8 then ' more-than-one-digit' else '')
      iconAnchor: [8.666, 29]
      html:       markerHtml
    ($ icon).data 'placement', 'left'
    marker = L.marker def.location,
      icon: icon
      title: def.label
    u.events marker, def.events
    marker.addTo @m.map
    if def.area
      circle = (L.circle def.location, def.location.distance, { color: u.activityAreaColor, stroke: false })
      circle.addTo @m.map
      [marker, circle]
    else marker

  distanceChanged: throttle 100, -> @moveLocation true
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
      later 10, => @d.geoLocation.removeClass 'active'
  notify: -> if @doNotify and @data.onChange? then @runNotify()
  runNotify: debounce 500, ->
    (l = @data.location)?.distance = distance = @getDistance()
    @data.onChange l, distance

  ensureInit: (done) ->
    # TODO initv2: wait if map is needed only
    unless L?
      later (@wait*=2), => @ensureInit(done)
      return
    @doInit()
    done()

  _doInit: ->
    # TODO initv2: remove once; instead, add and remove components as configured
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
    # @m.search = u.w.createLocationTypeahead @d.search, @data.location?.label, ((event, location) => @setLocation location, true), => @data.location
    @m.search = u.w.createLocationTypeahead2 @d.search, ((event, location) => @setLocation location, true), => @data.location
    unless @d.map?.length then @c.map.empty().append(@d.map = $ '<div class="map"></div>')
    unless (@m.map = @d.map.data 'leafletMap')?
      @m.map = map = L.map @d.map[0],
        center: @data?.location ? [0,0]
        zoom: 13
      # add an OpenStreetMap tile layer
      L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', { attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'}).addTo map
      @d.map.data 'leafletMap', map
      @m.rect = (L.rectangle [[0,0],[0,0]], { color: u.pickLocationRectColor, weight: 1 })
      @m.circle = (L.circle [0,0], 0, { color: u.pickLocationRectColor, weight: 1 })
      @m.marker = L.marker [0, 0], title: 'current location'

    # hook up event handlers
    #@d.distance.on 'change', => @distanceChanged()
    @d.distance.on 'change', => @distanceChanged()
    @m.map.on 'click', (e) => @mapClicked e
    @d.geoLocation.on 'click', => @geoLocationClicked()

