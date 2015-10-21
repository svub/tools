_.extend Mongo.Collection.prototype,
  put: (obj, callback, options = {}) ->
    check obj, Object
    if (id = obj._id)?
      check id, String
      delete obj._id
      @update { _id: id }, { $set: obj }, options, callback
      obj._id = id # put the ID back :)
    else
      logm 'ce.put: insert', obj
      if callback?
        @insert obj, (error, id) ->
          obj._id = id unless error?
          callback error, id
      else
        obj._id = logm 'ce.put: inserted', @insert obj
    logm 'ce.put: final', obj
  putOnce: (obj) ->
    check obj, Object
    if not (@findOne obj)?
      @put obj
      true
    else false
  removeAll: (query) -> # for client side - as client side does permit deleting by ID only.
    found = (find = @find query).count() > 0
    if Meteor.isClient then @remove { _id: toBeRemoved._id } for toBeRemoved in find.fetch()
    else @remove query
    found
  toggle: (obj, putIn) ->
    if putIn then @putOnce obj
    else @removeAll obj
  findAll: (ids) ->
    if _.isString ids then ids = [ids]
    if not ids? or ids.length < 1 then return []
    #logm 'collection.getAll: ids', ids
    if ids.length is 1 then @find _id: ids[0]
    #else @find logm "collection.getAll ids=#{ids}; query", $or: (_id : id for id in ids)
    else @find $or: (_id : id for id in ids)
  getAll: (ids) ->
    try @findAll(ids).fetch() catch
      return []
