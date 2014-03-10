# CollectionBehaviours.defineBehaviour 'owned', (getTransform, args) ->
  # @before.insert (userId, doc) -> doc.owner = userId
# 
# CollectionBehaviours.defineBehaviour 'rememberLastUpdater', (getTransform, args) ->
  # @before.insert (userId, doc) -> doc.lastUpdatedBy = userId
  # @before.update (userId, doc, fieldNames, modifier, options) -> (modifier.$set ?= {}).lastUpdatedBy = userId
