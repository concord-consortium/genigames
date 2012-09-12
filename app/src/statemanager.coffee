###
STATES:

  inTask
    showingBreeder
###

minispade.require 'genigames/statechart/in-world'
minispade.require 'genigames/statechart/in-town'
minispade.require 'genigames/statechart/in-task'

GG.statemanager = Ember.StateManager.create
  # enableLogging: true         # uncomment to log state transitions during development

  initialState: 'loading'
  params: {}

  loading: Ember.State.create({})

  loggingIn: Ember.State.create
    enter: ->
      #try to log in automatically
      GG.sessionController.checkCCAuthToken()

      # show the login form
      GG.universeView.set 'currentView', GG.universeView.get 'login'
      if GG.sessionController.get('user')?
        setTimeout ->
          GG.statemanager.send 'successfulLogin'
        , 100

    login: (state, data)->
      GG.sessionController.loginPortal(data.username, data.password)

    successfulLogin: ->
      # load the game after we log in so that we can create towns and tasks
      # with the current user's saved state
      loadGame = ->
        # GET /api/game
        # set the player's task according to the game specification
        gamePath = if UNDER_TEST? then 'api/testgame' else 'api/game'
        $.getJSON gamePath, (data) ->
          for to in data.towns
            town = GG.Town.create to
            GG.townsController.addTown town
          GG.statemanager.goToState('inWorld')

        $.getJSON '/couchdb/genigames/actionCosts', (data) ->
          actionCosts = GG.ActionCosts.create data
          GG.actionCostsController.set 'content', actionCosts

      if GG.statemanager.get('params').learner?
        obs = ->
          GG.userController.removeObserver('loaded', obs)
          loadGame()
        GG.userController.addObserver('loaded', obs)
        GG.userController.set('learnerId', GG.statemanager.get('params').learner)
      else
        loadGame()

  loggingOut: Ember.State.create
    enter: ->
      GG.sessionController.logoutPortal()

  inWorld: GG.StateInWorld,

  inTown: GG.StateInTown,

  inTask: GG.StateInTask