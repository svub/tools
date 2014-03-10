_.extend u.p,
  hasRole: (role, id) ->
    check role, Match.Where (role) => role in @roles 
    Roles.userIsInRole (if id? then u.u.get id else Meteor.user()), role
  isAdmin: (id) -> @hasRole @admin, id
  isUserAdmin: -> @hasRole @userAdmin
  isTypeEditor: -> @hasRole @typeEditor
  admin: 'admin'
  userAdmin: 'user-admin'
  typeEditor: 'type-editor'

u.p.roles = [u.p.admin, u.p.userAdmin, u.p.typeEditor]
