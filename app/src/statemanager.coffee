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
      if GG.statemanager.get('params').learner?
        # TODO We should probably enforce that the learner passed in via params
        # is one of the learners the portal returns as part of the cc auth token data
        GG.userController.set('learnerId', GG.statemanager.get('params').learner)
      else
        # find the learners listed in the response
        data = GG.sessionController.get('user')
        found = GG.sessionController.get('classesWithLearners')
        if found.length > 1
          # if multiple, display a selection dialog
          GG.universeView.set 'currentView', GG.universeView.get 'chooseClass'
          return
        else if found.length == 1
          # if one, use that learner
          GG.userController.set('learnerId', found[0].learner)
        else
          # if none, set GG.userController.loaded = true
          GG.userController.set('loaded', true)

      GG.statemanager.send 'load'

    chooseLearner: (state, learner)->
      GG.userController.set('learnerId', learner)
      GG.statemanager.send 'load'

    load: ->
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
          # fixme: this should be eventually handled by a router
          if (taskPath = GG.statemanager.get('params.task'))
            taskPath = taskPath.split "/"
            townLoaded = GG.townsController.loadTown taskPath[0]
            GG.tasksController.loadTask parseInt(taskPath[1])-1 if not isNaN parseInt(taskPath[1])
            nextState = if townLoaded then 'inTown' else 'inWorld'
            GG.statemanager.transitionTo nextState
          else
            GG.statemanager.transitionTo 'inWorld'

        $.getJSON '/couchdb/genigames/actionCosts', (data) ->
          actionCosts = GG.ActionCosts.create data
          GG.actionCostsController.set 'content', actionCosts

      if GG.userController.get('loaded')
        loadGame()
      else
        obs = ->
          if GG.userController.get('loaded')
            GG.userController.removeObserver('loaded', obs)
            loadGame()
        GG.userController.addObserver('loaded', obs)

  loggingOut: Ember.State.create
    enter: ->
      GG.sessionController.logoutPortal()

  inWorld: GG.StateInWorld,

  inTown: GG.StateInTown,

  inTask: GG.StateInTask
