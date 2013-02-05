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
      unless GG.sessionController.get('preloadingComplete')
        assets = Assets.preloadCssImages
          statusTextEl: "#loadingStatus"
          showImageName: false
          onComplete: ->
            $('#loadingStatus').html("Loading complete.")
            GG.sessionController.set('preloadingComplete', true)
        # for asset in assets
        #   console.log("pre-loading: " + asset)

      #try to log in automatically
      GG.sessionController.set('loggingIn', true)
      GG.sessionController.checkCCAuthToken()

      # show the login form
      GG.universeView.setCurrentView 'login'
      if GG.sessionController.get('user')?
        setTimeout ->
          GG.statemanager.send 'successfulLogin'
        , 100

    login: (state, data)->
      GG.sessionController.set('loggingIn', true)
      GG.sessionController.loginPortal(data.username, data.password)

    successfulLogin: (manager)->
      if GG.sessionController.get('preloadingComplete')
        manager.send 'preloadedSuccessfulLogin'
      else
        console.log("waiting for preload to finish")
        GG.sessionController.set('waitingForPreload', true)
        GG.sessionController.addObserver 'preloadingComplete', ->
          GG.sessionController.removeObserver 'preloadingComplete', this
          manager.send 'preloadedSuccessfulLogin'

    preloadedSuccessfulLogin: ->
      Ember.run.next ->
        GG.sessionController.set('waitingForPreload', false)
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
          GG.universeView.setCurrentView 'chooseClass'
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
          # re-construct the data into heirarchical format, since
          # couchdb doesn't make that easy to do before delivering it
          items = {
            'task': {},
            'town': {},
            'world': {}
          }
          for item in data.rows
            items[item.key][item.id] = item.value

          # now embed tasks into towns
          for own t of items.town
            children = []
            for ta in items.town[t].tasks
              children.push(items.task[ta])
            items.town[t].tasks = children

          for own wo of items.world
            children = []
            for tow in items.world[wo].towns
              if !items.town[tow] then console.log("No town named #{tow}"); continue
              children.push(items.town[tow])
            items.world[wo].towns = children

          # TODO Instead of just using the "game" world, perhaps we can
          # have some way to set this externally?
          for to in items.world.game.towns
            town = GG.Town.create to
            GG.townsController.addTown town
          # fixme: this should be eventually handled by a router
          if (taskPath = GG.statemanager.get('params.task'))
            taskPath = taskPath.split "/"
            if taskPath[0] is "baseline"
              GG.baselineController.set 'isBaseline', true
              townLoaded = GG.townsController.loadTown taskPath[1]
              GG.tasksController.setCurrentTask GG.tasksController.objectAt parseInt(taskPath[2])-1
              Ember.run ->
                GG.universeView.setCurrentView 'baseline'
              GG.statemanager.transitionTo 'inTask'
            else
              townLoaded = GG.townsController.loadTown taskPath[0]
              GG.tasksController.setNextAvailableTask parseInt(taskPath[1])-1 if not isNaN parseInt(taskPath[1])
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
