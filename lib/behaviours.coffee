crudAllow =
  insert: (userId, doc) -> true
  update: (userId, doc, fieldNames, modifier) -> true
  remove: (userId, doc) -> true
crudDeny =
  insert: (userId, doc) -> false
  update: (userId, doc, fieldNames, modifier) -> false
  remove: (userId, doc) -> false

CollectionBehaviours.defineBehaviour 'owned', (getTransform, args) ->
  isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
  mineOrAdmin = (userId, doc) -> userId? and ((doc.owner is userId) or isAdmin())
  @before.insert (userId, doc) => doc.owner = userId unless isAdmin() and doc.owner?
  @before.update (userId, doc, fieldNames, modifier, options) =>
    if not isAdmin() then delete modifier?.$set?.owner
  # @allow _.extend crudAllow,
  @allow
    # update: (userId, doc, fields, modifier) -> (doc.owner is userId) or isAdmin()
    # remove: (userId, doc) -> (doc.owner is userId) or isAdmin()
    insert: (userId, doc) => mineOrAdmin userId, doc
    update: (userId, doc) =>
      logm "#{@_name}.behaviour.owned.allow.update #{doc._id}", mineOrAdmin userId, doc
    remove: (userId, doc) => logm "#{@_name}.behaviour.owned.allow.remove #{doc._id}", mineOrAdmin userId, doc
  @deny
    update: (userId, doc, fields, modifier) =>
      logm "#{@_name}.behaviour.owned.deny.update", ('owner' in fields) and not isAdmin()

CollectionBehaviours.defineBehaviour 'rememberLastUpdater', (getTransform, args) ->
  @before.insert (userId, doc) -> doc.lastUpdatedBy = userId
  @before.update (userId, doc, fieldNames, modifier, options) -> (modifier.$set ?= {}).lastUpdatedBy = userId

CollectionBehaviours.defineBehaviour 'indexLocation', (getTransform, args) ->
  # expects function(doc) -> return location or name of location property
  propertyValue = if _.isString(propertyName = x = (asArray args)[0]) then (obj) -> u.getValue obj, x else x
  propertyIndex = args[1] ? "#{propertyName}Index"
  check propertyValue, Function; check propertyIndex, String
  #logmr 's.c.beh.indexLocation: this.ensureIndex', @_ensureIndex
  if Meteor.isServer then @_ensureIndex properyName: '2dsphere'
  createLocationIndex = (object) -> if (l = propertyValue object)?
    object[propertyIndex] = type: 'Point', coordinates: [l.lng ? 0, l.lat ? 0]
  @before.insert (userId, doc) -> createLocationIndex doc
  @before.update (userId, doc, fieldNames, modifier, options) ->
    if (index = createLocationIndex doc)? then (modifier.$set ?= {})[propertyIndex] = index
    else (modifier.$unset ?= {})[propertyIndex] = true

CollectionBehaviours.defineBehaviour 'noDelete', (getTransform, args) ->
  isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
  @allow crudAllow
  @deny
    remove: (userId, doc) ->
      logm "#{@_name}.behaviour.noDelete.deny.remove", not isAdmin()

CollectionBehaviours.defineBehaviour 'loggedInOnly', (getTransform, args) ->
  isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
  @allow crudAllow
  ifNotLoggedIn = (userId) -> not userId?
  @deny insert: ifNotLoggedIn, update: ifNotLoggedIn, remove: ifNotLoggedIn

CollectionBehaviours.defineBehaviour 'requiresRole', (getTransform, args) ->
  logmr "#{@_name}.behaviour.requiresRole: args", args
  if _.isString args then args = [args]
  check args, [String]
  @allow crudAllow
  @deny
    remove: (userId, doc) ->
      logm "#{@_name}.behaviour.requiresRole.deny.remove", not Roles.userIsInRole Meteor.user(), args
