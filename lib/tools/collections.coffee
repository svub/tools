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
	mineOrAdmin = (userId, doc) -> (doc.owner is userId) or isAdmin()
	@before.insert (userId, doc) => doc.owner = userId
	@before.update (userId, doc, fieldNames, modifier, options) =>
		if not isAdmin() then delete modifier?.$set?.owner
	# @allow _.extend crudAllow,
	@allow
		# update: (userId, doc, fields, modifier) -> (doc.owner is userId) or isAdmin()
		# remove: (userId, doc) -> (doc.owner is userId) or isAdmin()
		insert: (userId, doc) => mineOrAdmin userId, doc
		update: (userId, doc) =>
			logm "#{@_name}.behaviour.owned.allow.update #{EJSON.stringify doc}", mineOrAdmin userId, doc
		remove: (userId, doc) => logm "#{@_name}.behaviour.owned.allow.remove", mineOrAdmin userId, doc
	@deny
		update: (userId, doc, fields, modifier) =>
			logm "#{@_name}.behaviour.owned.deny.update", ('owner' in fields) and not isAdmin()

CollectionBehaviours.defineBehaviour 'rememberLastUpdater', (getTransform, args) ->
	@before.insert (userId, doc) -> doc.lastUpdatedBy = userId
	@before.update (userId, doc, fieldNames, modifier, options) -> (modifier.$set ?= {}).lastUpdatedBy = userId

CollectionBehaviours.defineBehaviour 'noDelete', (getTransform, args) ->
	isAdmin = -> Roles? and Roles.userIsInRole Meteor.user(), 'admin'
	@allow crudAllow
	@deny
		remove: (userId, doc) ->
			logm "#{@_name}.behaviour.noDelete.deny.remove", not isAdmin()

CollectionBehaviours.defineBehaviour 'requiresRole', (getTransform, args) ->
	logmr "#{@_name}.behaviour.requiresRole: args", args
	if _.isString args then args = [args]
	check args, [String]
	@allow crudAllow
	@deny
		remove: (userId, doc) ->
			logm "#{@_name}.behaviour.requiresRole.deny.remove", not Roles.userIsInRole Meteor.user(), args

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
	logm 'collection.getAll: ids', ids
	if _.isString ids then ids = [ids]
	logm 'collection.getAll: ids', ids
	if not ids? or ids.length < 1 then return []
	logm 'collection.getAll: ids', ids
	if ids.length is 1 then @find { _id: ids[0] }
	else
		all = ({ _id : id } for id in ids)
		@find logm "collection.getAll ids=#{ids}; query", { $or: all }
Meteor.Collection.prototype.getAll = (ids) ->
	try @findAll(ids).fetch() catch
		return []

collections = []
collections.push @activities  = u.activities  = new Meteor.Collection 'activities'
collections.push @types       = u.types       = new Meteor.Collection 'types'
collections.push @messages    = u.messages    = new Meteor.Collection 'messages'
copyUsers = -> collections.push @users = u.users = Meteor.users
if Meteor.users? then copyUsers() else Meteor.startup copyUsers

collection.allow crudAllow for collection in collections # first, allow anything
u.activities.owned()
u.activities.timestampable()
u.messages.owned()
u.messages.timestampable()
u.types.rememberLastUpdater()
u.types.timestampable()
u.types.noDelete()
u.types.requiresRole u.p.typeEditor
u.types.deny
	update: (userId, doc, fields, modifier) ->
		logmr 'u.types.deny.update: fields', fields
		logmr 'u.types.deny.update: profiles', modifier.$set.profiles
		deny = false
		if not u.p.isAdmin()
			# deny updating anything but the profiles
			if Meteor.isClient and _.difference(fields,['profiles']).length > 0 then deny = true
			# deny removing type names
			if not deny and (newProfiles = modifier?.$set?.profiles)?
				for newProfile in newProfiles
					lang = newProfile.lang
					oldProfile = _.find doc?.profiles, (profile) -> profile?.lang == lang
					deny ||= (oldLabels = oldProfile?.labels?.copy?())? and newProfile.labels? and newProfile.labels.length < oldLabels.length
					logmr "u.types.deny.update: lang=#{lang}, deny=#{deny}, oldLabels", oldLabels
					logmr "u.types.deny.update: newLabels", newProfile.labels
		logmr "u.types.deny.update: deny", deny
if Meteor.isServer
	# u.flaggedTypes       = new Meteor.Collection 'flaggedTypes'
	# u.flaggedActivities  = new Meteor.Collection 'flaggedActivities'
	u.flaggedTypes       = new Meteor.Voting 'flaggedTypes', u.types, null, { down: 'flagged', up: 'approved' }
	u.flaggedActivities  = new Meteor.Voting 'flaggedActivities', u.activities, null, { down: 'flagged', up: 'approved' }
	u.userVotes          = new Meteor.Voting 'userVotes', Meteor.users
	u.activityVotes      = new Meteor.Voting 'activityVotes', u.activities
	u.following          = new Meteor.Voting 'following', u.users, u.users, { up: 'followers', down: 'muted', sourceListUp: 'profile.following', sourceListDown: 'profile.muted' }
	u.joining            = new Meteor.Voting 'joining', u.activities, u.users, { up: 'joiningCount', targetListUp: 'joining' }
	u.notifyAboutChanges = new Meteor.Voting 'notifyAboutChanges', u.activities, u.users, { targetListUp: 'notify.changes' }
	# Meteor.publish 'activities', -> activities.find {}, { sort: { date: -1 } }
	# Meteor.publish 'types',      -> types.find()
	# Meteor.publish 'users',      -> Meteor.users.find()
	# Meteor.publish 'myFlaggedTypes', -> u.flaggedTypes.find { user: @userId }
	# Meteor.publish 'myFlaggedActivities', -> u.flaggedActivities.find { user: @userId }
	Meteor.publish 'myFlaggedTypes', -> u.flaggedTypes.findVoted @userId
	Meteor.publish 'myFlaggedActivities', -> u.flaggedActivities.findVoted @userId
	Meteor.publish 'myUserVotes', -> u.userVotes.find { $or: [ { voter: @userId }, { voted: @userId } ] }
	Meteor.publish 'chat', (contextId) -> u.messages.find { context: contextId }, { sort: { createdAt: -1 }, limit: 100 }
	# createSuggestWrapper = (obj, label) -> { _id: (if _.isString obj then obj else obj._id), label: label }
	limitSuggestions = { limit: u.maxSuggestions }
	Meteor.methods
		flagType: (typeId, flag=true, why=null) ->
			check activityId, String
			check plus, Match.OptionalAndNull Boolean
			check why, Match.OptionalAndNull String
			# if (logm 'm.flagType', @userId)? then u.flaggedTypes.toggle { user: @userId, type: typeId }, flag
			u.flaggedTypes.vote @userId, typeId, not flag, why
		flagActivity: (activityId, flag=true, why=null) ->
			check activityId, String
			check plus, Match.OptionalAndNull Boolean
			check why, Match.OptionalAndNull String
			# if (logm 'm.flagActivity', @userId)? then u.flaggedActivities.toggle { user: @userId, activity: activityId }, flag
			u.flaggedActivities.vote @userId, activityId, not flag, why

		voteUser: (userId, plus=true, why=null) ->
			check userId, String
			check plus, Match.OptionalAndNull Boolean
			check why, Match.OptionalAndNull String
			u.userVotes.vote @userId, userId, plus, why
		unvoteUser: (userId) ->
			check userId, String
			u.userVotes.unvote @userId, userId
		voteActivity: (id, plus=true, why=null) ->
			check id, String
			check plus, Match.OptionalAndNull Boolean
			check why, Match.OptionalAndNull String
			u.activityVotes.vote @userId, id, plus, why
		unvoteActivity: (id) ->
			check id, String
			u.activityVotes.unvote @userId, id
		follow: (id) ->
			check id, String
			u.following.vote @userId, id, true
		unfollow: (id) ->
			check id, String
			u.following.unvote @userId, id
		join: (id) ->
			check id, String
			u.joining.vote @userId, logm 's.c.join', id
		disjoin: (id) ->
			check id, String
			u.joining.unvote @userId, id
		notifyAboutChanges: (id) ->
			check id, String
			u.notifyAboutChanges.vote @userId, id
		stopNotifyAboutChanges: (id) ->
			check id, String
			u.notifyAboutChanges.unvote @userId, id
		suggestUser: (query) ->
			check query, String
			logm "s.c.suggestUser for '#{query}'", (for user in (Meteor.users.find({ 'profile.name': { $regex : query, $options : 'i' } }, limitSuggestions).fetch())
				u.p.createSuggestionWrapper user, user.profile.name)
		suggestType: (query, lang=u.getLang()) ->
			check query, String
			check lang, String
			wrap = (typeObject, label) ->
				label ?= u.t.getDefaultLabel typeObject, lang
				u.p.createSuggestionWrapper typeObject, label
			find = (regex) =>
				for typeObject in types.find({ profiles: { $elemMatch: { labels: { $regex : regex, $options : 'i' } } } }, limitSuggestions).fetch()
					wrap typeObject, u.t.matchingLabel typeObject, typeName
			typeName = _s.trim query
			suggestions = find typeName
			if suggestions?.length < 1 and typeName.indexOf ' ' > 0 then suggestions = find typeName.split(' ').join('|')
			logm "search.types.suggest for '#{typeName}'", suggestions
		recentTypes: -> logmr 'c.recentTypes', u.t.recent @userId
		popularTypes: -> logmr 'c.popularTypes', u.t.popular()
		recentActivities: -> logmr 'c.recentActivities', u.a.recent @userId
		popularActivities: -> logmr 'c.popularActivities', u.a.popular 20, undefined


if Meteor.isClient
	# TODO any sense in subscribing to activities, types, and users?
	u.subscriptions =
		activities          : Meteor.subscribe 'activities'
		types               : Meteor.subscribe 'types'
		users               : Meteor.subscribe 'users'
		myFlaggedTypes      : Meteor.subscribe 'myFlaggedTypes'
		myFlaggedActivities : Meteor.subscribe 'myFlaggedActivities'
		#myUserVotes         : Meteor.subscribe 'myUserVotes' - don't need to subscribe from the start
	# link collections for iron router resource package to find them automatically
	window.Activities = @activities;
	window.Types = @types;
	u.users = window.Users = Meteor.users;
	u.flaggedTypes      = new Meteor.Collection 'flaggedTypes'
	u.flaggedActivities = new Meteor.Collection 'flaggedActivities'

# if Meteor.isClient
	# # make collections globally visible
	# console.log 'collections loaded.'
	# window.activities = activities
	# window.types      = types
	# window.messages   = messages

# if Meteor.isServer
	# console.log (k for k of activities)
	# activities.ensureIndex( { type: 1, location: "2dsphere", date: 1, }, { name: "umeedoo.search-index" } )
