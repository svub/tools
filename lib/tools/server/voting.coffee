# Provides voting/rating functionality for one item of a collection rating an item of the same or different collection
# Simultaneously, it can keep a list of 
# * raters/voters IDs in the voted item
# * rated/voted item IDs in the voter
# All fields are customizable.
#
# voting = new Voting(name, target, source, fields)
# name: name of collection to store the link object between source and target
# target: collection of items to be rated/voted
# source: collection voters/raters (optional)
# fields: (optional)
#   up               name of field in target/voted to store the count of up-votes ("thumb up")
#   down             name of field in target/voted to store the count of down-votes ("thumb down")
#   sourceListUp     name of field in source/voter to store the IDs of the item voted-down on
#   sourceListDown   name of field in source/voter to store the IDs of the item voted-down on
#   targetListUp     name of field in target/voted to store the IDs of the voters who voted this item down
#   targetListDown   name of field in target/voted to store the IDs of the voters who voted this item down
#
# The lists (arrays) are for convenience, otherwise voting.getVoter(votedId) or voting.getVoted(voterId) can be used.
#
# voting.vote(voter, voted, up, why)
#   voter ID from the source collection
#   voted ID from the target collection
#   up    up or down vote (optional, default: up=true)
#   why   string that can contain why a voter voted an item down (optional)
#
# voting.unvote(voter, voted)
#   removes any previous voting; see @vote
#
# Use cases
# Report and approve items by users: 
# checkedItems = new Voting("checkedItems", items, Meteor.users, { up:"approved", down:"reported", sourceListDown:"reportedItems", sourceListUp:"approvedItems", targetListDown:"reportedBy", targetListUp:"approvedBy" }
#
# Rate items by users
# u.userVotes = new Voting("userVotes", Meteor.users)
# will vote on Meteor.users collection; default fields are { up: "votesUp"; down: "votesDown" }

class Voting extends Meteor.Collection
  
  # name of collection; tagrgets: collection that will be voted on; source: collection of voters (optional); @sourceListField: an array that will contain all IDs that this source voted for
  constructor: (@name, @targets, @source, @fields={}) -> 
    check @name, String
    check @targets?.find, Match.OptionalOrNull Function
    check @source?.find, Match.OptionalOrNull Function
    check @fields, Match.OptionalOrNull Object
    super @name
    if _.isEmpty @fields
      @fields.up   = 'votesUp'
      @fields.down = 'votesDown'
  
  # helpers
  log: log ? (obj) ->
    console?.log obj
    obj
  logmr: logmr ? (msg, obj) ->
    @log msg
    @log obj
  createObject: createObject ? ->
    object = {}
    for o,i in arguments
      if i%2==1 and (key = arguments[i-1])? then object[key] = o
    object
  _updateLists: (voter, voted, up) ->
    check voter, String
    check voted, String
    if up? # put in
      @logmr "Voting #{@name}.ulists: up=#{up}; fields", @fields
      if (list = if up then @fields.sourceListUp else @fields.sourceListDown)? and @source?
        @source.update { _id: voter }, { $addToSet: @createObject list, voted }
      if (list = if up then @fields.targetListUp else @fields.targetListDown)? and @targets?
        @logmr "Voting #{@name}.ulists: list=#{list}", { $addToSet: @createObject list, voter }
        @log @targets.update { _id: voted }, { $addToSet: @createObject list, voter }
    else # pull out
      if not _.isEmpty(set = @createObject(@fields.sourceListUp, voted, @fields.sourceListDown, voted))
        @source.update { _id: voter }, { $pull: set }
      if not _.isEmpty(set = @createObject(@fields.targetListUp, voter, @fields.targetListDown, voter))
        @targets.update { _id: voted }, { $pull: set }
  
  # short cuts
  up: (voter, voted, why=null) -> @vote voter, voted, true, why
  down: (voter, voted, why=null) -> @vote voter, voted, false, why
  
  vote: (voter, voted, up=true, why=null) ->
    check voter, String
    check voted, String
    @unvote voter, voted
    @logmr "Voting #{@name}.vote: vote", @insert { voter: voter, voted: voted, up: up, why: why }
    # update counters
    if (field = if up then @fields.up else @fields.down)?
      # MAYBE calculate *real* votes now and then via @findVoted(...).count() and @findVoter
      inc = @logmr "Voting #{@name}.vote: inc", @createObject field, 1
      @logmr "Voting #{@name}.vote: target", @targets.update { _id: voted }, { $inc: inc }
    @_updateLists voter, voted, up
  unvote: (voter, voted) ->
    check voter, String
    check voted, String
    for vote in @getVotes voter, voted # actually, should be one at any time only
      inc = if (list = if vote.up then @fields.up else @fields.down)? then @createObject list, -1
      if inc? then @logmr "Voting #{@name}.unvote target", @targets.update { _id: voted }, { $inc: inc }
      @logmr "Voting #{@name}.unvote: vote", @remove { _id: vote._id }
    @_updateLists voter, voted
  
  getVotes: (voter, voted) -> 
    check voter, String
    check voted, String
    @find({ voter: voter, voted: voted }).fetch() # Again, should always return one only...
  findVoters: (voted) -> 
    check voted, String
    @find { voted: voted }
  getVoters: (voted) -> 
    _.pluck @findVoters(voted).fetch(), 'voter'
  findVoted: (voter) -> 
    check voter, String
    @find { voter: voter }
  getVoted: (voter) -> 
    _.pluck @findVoted(voter).fetch(), 'voted'

Meteor.Voting = Voting