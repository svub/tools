
### alerts ############################################################################################################

u.alert = (message, type = 'info', delay = 6000) ->
	$.bootstrapGrowl message,
		# ele: 'body'                          # which element to append to
		type:   type                           # null, 'info', 'error', 'success'
		offset: { from: 'top', amount: ($('header').outerHeight() + 10) } # do not overlay header
		align:  (if type == 'info' then 'right' else 'center')                       # 'left', 'right', or 'center'
		width:  250                           # integer, or 'auto'
		delay:  delay
		allow_dismiss: (not (type in ['error', 'danger']))
		stackup_spacing: 10                  # spacing between consecutively stacked growls.

u.alert.warning = (message) -> u.alert message, 'warning'
u.alert.error = (message) -> u.alert message, 'danger', 8000
u.alert.success = (message) -> u.alert message, 'success'
u.events = (e, map) ->
	for type, fn of map
		if fn? then e.on type, fn

Meteor.callCached ?= (method, parameters...) ->
	# TODO JSON.stringify parameters and add to sessionKey?
	sessionKey = "callCache_#{method}"
	(Session.get sessionKey) ? Meteor.apply method, parameters, (error, data) ->
		Session.set sessionKey, if error? then undefined else data
