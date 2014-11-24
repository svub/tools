_.extend u.x,
  geonames:
    countries: (callback) ->
      cheerio = Npm.require 'cheerio'
      url = 'http://api.geonames.org/countryInfo?username=demo'
      $ = cheerio.load Meteor.http.get(url).content
      countries = for country in $.find("country")
        parsed = {}
        #$(country).find('> *').each -> parsed[@nodeName] = $(@).text()
        country.find('> *').each -> parsed[@nodeName] = $(@).text()
        parsed.label = parsed.countryName
