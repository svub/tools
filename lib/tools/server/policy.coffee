Meteor.startup ->
  # Leaflet
  # BrowserPolicy.content.allowImageOrigin 'http://*.tile.osm.org/'
  # BrowserPolicy.content.allowEval() # needed for leaflet 0.7 :( - fixed in v 0.7.1 :)
  BrowserPolicy.content.allowScriptOrigin 'http://cdn.leafletjs.com/leaflet-0.7.2/leaflet.js'
  BrowserPolicy.content.allowStyleOrigin 'http://cdn.leafletjs.com/leaflet-0.7.2/leaflet.css'
  BrowserPolicy.content.allowOriginForAll 'cdn.leafletjs.com'

  # shareit package
  BrowserPolicy.content.allowScriptOrigin 'https://platform.twitter.com/widgets.js'
  BrowserPolicy.content.allowScriptOrigin 'http://connect.facebook.net/en_US/all.js'
  
  # Google font for headings
  BrowserPolicy.content.allowStyleOrigin 'http://fonts.googleapis.com/css'
  BrowserPolicy.content.allowFontOrigin 'http://themes.googleusercontent.com/static/fonts/lato/v7/9k-RPmcnxYEPm8CNFsH2gg.woff'
  BrowserPolicy.content.allowFontOrigin 'http://themes.googleusercontent.com/static/fonts/lato/v7/wkfQbvfT_02e2IWO3yYueQ.woff'
  BrowserPolicy.content.allowFontOrigin 'themes.googleusercontent.com'
  
  BrowserPolicy.content.allowImageOrigin '*' # to allow avatar images to be loaded from anywhere
