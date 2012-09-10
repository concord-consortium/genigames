###
STATES:

  inTask
    showingBreeder
###

minispade.require 'genigames/statechart/in-world'
minispade.require 'genigames/statechart/in-town'
minispade.require 'genigames/statechart/in-task'

GG.statemanager = Ember.StateManager.create
  initialState: 'loading'
  params: {}

  loading: Ember.State.create

  loggingIn: Ember.State.create
    enter: ->
      #try to log in automatically
      GG.sessionController.checkCCAuthToken()

      # show the login form
      GG.universeView.set 'currentView', GG.universeView.get 'login'
      if GG.sessionController.get('user')?
        setTimeout ->
          GG.statemanager.goToState('inWorld')
        , 100

    login: (state, data)->
      GG.sessionController.loginPortal(data.username, data.password)

  loggingOut: Ember.State.create
    enter: ->
      GG.sessionController.logoutPortal()

  inWorld: GG.StateInWorld,

  inTown: GG.StateInTown,

  inTask: GG.StateInTask