if Meteor.isServer
  # intercept publish method to track publications
  mp = Meteor.publish
  counts = {}
  Meteor.startup -> counts = {}
  totalCounts = ->
    u.createObject doc, (_.keys (ids ? {})).length for own doc, ids of counts
  countTotal = (doc, id) ->
    counts[doc] ?= {}
    counts[doc][id] ?= 0
    counts[doc][id]++
  count = (docs) ->
    results = {}
    for own doc, idMap of docs
      c = (ids = _.keys idMap).length
      results[doc] = c
      countTotal doc, id for id in ids
    results
  Meteor.publish = (name, method)->
    mp.call Meteor, name, ->
      r = method.apply @, arguments
      if u?.track?.publications
        logmr "track: Meteor.publish '#{name}': arguments", arguments
        logmr "... documents", count @_documents
        logmr "... totals", totalCounts()
      r

else # client
  # intercept subscribe method to track subscriptions
  ms = Meteor.subscribe
  Meteor.subscribe = ->
    if u?.track?.subscriptions
      if u?.track?.traceSubscriptions
        logt "track: Meteor.subscribe '#{arguments[0]}': location"
        logmr '... arguments', arguments
      else
        logmr "track: Meteor.subscribe '#{arguments[0]}': arguments", arguments
    ms.apply Meteor, arguments

_.extend u,
  track:
    publications: false # print parameters and number of published documents
    subscriptions: false # print parameters for subscriptions
    traceSubscriptions: false # print stack trace for each subscription call
