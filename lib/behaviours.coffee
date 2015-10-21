crudAllow =
  insert: (userId, doc) -> true
  update: (userId, doc, fieldNames, modifier) -> true
  remove: (userId, doc) -> true
crudDeny =
  insert: (userId, doc) -> false
  update: (userId, doc, fieldNames, modifier) -> false
  remove: (userId, doc) -> false
isAdmin = (uid) -> Roles? and Roles.userIsInRole uid, 'admin'

# TODO replace local isAdmin with global isAdmin above: CAREFUL: pass uid!
CollectionBehaviours.defineBehaviour 'owned', (getTransform, args) ->
  isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
  mineOrAdmin = (userId, doc) -> userId? and ((doc.owner is userId) or isAdmin())
  @before.insert (userId, doc) =>
    doc.owner = userId unless isAdmin() and doc.owner?
    true
  @before.update (userId, doc, fieldNames, modifier, options) =>
    delete modifier?.$set?.owner unless isAdmin()
    true
  @allow
    insert: (userId, doc) => mineOrAdmin userId, doc
    update: (userId, doc) =>
      logm "#{@_name}.behaviour.owned.allow.update #{doc._id}", mineOrAdmin userId, doc
    remove: (userId, doc) => logm "#{@_name}.behaviour.owned.allow.remove #{doc._id}", mineOrAdmin userId, doc
  @deny
    update: (userId, doc, fields, modifier) =>
      logm "#{@_name}.behaviour.owned.deny.update", ('owner' in fields) and not isAdmin()

CollectionBehaviours.defineBehaviour 'rememberLastUpdater', (getTransform, args) ->
  @before.insert (userId, doc) ->
    doc.lastUpdatedBy = userId
    true
  @before.update (userId, doc, fieldNames, modifier, options) ->
    (modifier.$set ?= {}).lastUpdatedBy = userId
    true

CollectionBehaviours.defineBehaviour 'indexLocation', (getTransform, args) ->
  # expects a function like (doc, modifiers) -> return location
  # or name of location property ("location", "profile.location", ...)
  propertyValue = (args = asArray args)[0]
  if _.isString(propertyName = propertyValue) then propertyValue = (obj, mods) ->
    location = mods?[propertyName] ? u.getValue obj, propertyName
  propertyIndex = (notEmpty args[1]) ? "#{propertyName}Index"
  check propertyValue, Function; check propertyIndex, String

  if Meteor.isServer then @_ensureIndex u.createObject propertyIndex, '2dsphere'
  createLocationIndex = (o, m) -> if (l = propertyValue o, m)?
    o[propertyIndex] = type: 'Point', coordinates: [l.lng ? 0, l.lat ? 0]

  @before.insert (userId, doc) ->
    createLocationIndex doc
    true
  @before.update (userId, doc, fieldNames, modifier, options) ->
    if (index = createLocationIndex doc, modifier)? then (modifier.$set ?= {})[propertyIndex] = index
    else (modifier.$unset ?= {})[propertyIndex] = true
    true

#isAdmin = (uid) -> Roles? and Roles.userIsInRole uid, 'admin'
#CollectionBehaviours.defineBehaviour 'noDelete', (getTransform, args) ->
#  @allow crudAllow
#  @deny
#    remove: (userId, doc) =>
#      logm "#{@_name}.behaviour.noDelete.deny.remove uid=#{userId}, doc.id=#{doc._id}", not isAdmin userId

CollectionBehaviours.defineBehaviour 'loggedInOnly', (getTransform, args) ->
  isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
  @allow crudAllow
  ifNotLoggedIn = (userId, doc) => logm "#{@_name}.behaviour.loggedInOnly.deny uid=#{userId} on doc=#{doc?._id}", not userId?
  @deny insert: ifNotLoggedIn, update: ifNotLoggedIn, remove: ifNotLoggedIn

CollectionBehaviours.defineBehaviour 'requiresRole', (getTransform, args) ->
  #if _.isString args then args = [args]
  args = asArray args
  logmr "#{@_name}.behaviour.requiresRole: args", args
  check args, [String]
  @allow crudAllow
  @deny
    remove: (userId, doc) ->
      #logm "#{@_name}.behaviour.requiresRole.deny.remove", not Roles.userIsInRole Meteor.user(), args
      logm "#{@_name}.behaviour.requiresRole.deny.remove", not Roles.userIsInRole userId, args

CollectionBehaviours.defineBehaviour 'logActions', (getTransform, args) ->
  logAction = (action) => (uid, doc, fields, modifier, options) =>
    logmr "#{@_name}.behaviour.logActions.#{action}: uid, fields, mods, options, doc", uid, fields, modifier, options, doc
  for method in ['insert', 'update', 'remove', 'find', 'findOne']
    @before[method] logAction method
