Meteor.createResponsiveVar = (initialValue) ->
  value = initialValue
  dep = new Deps.Dependency
  ->
    if arguments.length > 0
      unless EJSON.equals value, newValue = arguments[0]
        value = newValue
        do dep.changed
    else
      do dep.depend
      value
