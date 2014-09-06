Meteor.Collection.prototype.put = (obj) ->
  check obj, Object
  if (id = obj._id)?
    check id, String
    delete obj._id
    @update { _id: id }, { $set: obj }
    obj._id = id # put the ID back :)
  else
    obj._id = @insert obj
  obj
Meteor.Collection.prototype.putOnce = (obj) ->
  check obj, Object
  if not (@findOne obj)?
    @put obj
    true
  else false
Meteor.Collection.prototype.removeAll = (query) -> # for client side - as client side does permit deleting by ID only.
  found = @find(query).count() > 0
  if Meteor.isClient then @remove { _id: toBeRemoved._id } for toBeRemoved in @find(query).fetch()
  else @remove query
  found
Meteor.Collection.prototype.toggle = (obj, putIn) ->
  if putIn then @putOnce obj
  else @removeAll obj
Meteor.Collection.prototype.findAll = (ids) ->
  if _.isString ids then ids = [ids]
  if not ids? or ids.length < 1 then return []
  #logm 'collection.getAll: ids', ids
  if ids.length is 1 then @find _id: ids[0]
  #else @find logm "collection.getAll ids=#{ids}; query", $or: (_id : id for id in ids)
  else @find $or: (_id : id for id in ids)
Meteor.Collection.prototype.getAll = (ids) ->
  try @findAll(ids).fetch() catch
    return []
