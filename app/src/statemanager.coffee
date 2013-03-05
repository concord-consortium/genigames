###
STATES:

  inTask
    showingBreeder
###

minispade.require 'genigames/statechart/in-world'
minispade.require 'genigames/statechart/in-town'
minispade.require 'genigames/statechart/in-task'
minispade.require 'genigames/statechart/in-task-list'

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
      user = GG.sessionController.get('user')
      GG.logController.logEvent GG.Events.USER_LOGGED_IN,
        user:
          login: user.get('login')
          firstName: user.get('first')
          lastName: user.get('last')
          group: user.get('group')
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

      GG.statemanager.send 'nextStep'

    chooseLearner: (state, learner)->
      GG.userController.set('learnerId', learner)
      GG.statemanager.send 'nextStep'

    definedGroups: (state, data)->
      groupMembers = GG.groupsController.get('groups').map (item)->
        item.serialize()
      GG.logController.logEvent(GG.Events.GROUP_LOGGED_IN, {groupMembers: groupMembers})
      GG.userController.set('groupInfoSaved', true)
      GG.statemanager.send 'nextStep'

    nextStep: ->
      doNext = =>
        # load the game after we log in so that we can create towns and tasks
        # with the current user's saved state
        if GG.userController.get('loaded')
          GG.userController.removeObserver('loaded', obs)
          permissions = @checkCohorts()
          if permissions.approved
            if GG.userController.get('user.group') and not GG.userController.get('groupInfoSaved')
              GG.universeView.setCurrentView 'defineGroups'
              return
            else
              GG.statemanager.send 'loadGame'
          else
            # Permission denied!
            GG.logController.logEvent permissions.reason, {cohorts: GG.sessionController.get('user.cohorts')}
            $("#login-status").hide()
            $('#login-permission-denied').show()
            setTimeout ->
              console.log("Forwarding to portal...")
              window.location = "/portal/"
            , 3000

      if GG.userController.get('loaded')
        doNext()
      else
        obs = ->
          doNext()
        GG.userController.addObserver('loaded', obs)

    checkCohorts: ->
      u = GG.sessionController.get('user')
      if GG.worldName is "baseline"
        if not u.hasCohort("baseline")
          return {approved: false, reason: GG.Events.USER_DENIED_BASELINE}
      else if GG.worldName is "tournament"
        if not u.hasCohort("tournament")
          return {approved: false, reason: GG.Events.USER_DENIED_TOURNAMENT}
      else if not u.hasCohort("gamed")
        return {approved: false, reason: GG.Events.USER_DENIED_GAME}

      return {approved: true}

    loadGame: ->
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

        # get the appooropriate world and create its towns
        world = items.world[GG.worldName]
        console.log("using world: ", world)
        if world.species? and BioLogica.Species[world.species]?
           GG.DrakeSpecies = BioLogica.Species[world.species]
           GG.Genetics = new BioLogica.Genetics GG.DrakeSpecies
        for to in world.towns
          town = GG.Town.create to
          GG.townsController.addTown town

        # fixme: this should be eventually handled by a router
        if (taskPath = GG.statemanager.get('params.task'))
          taskPath = taskPath.split "/"
        if (taskPath)
          if taskPath[0] is "baseline"
            townLoaded = GG.townsController.loadTown taskPath[1]
            if taskPath[2]
              GG.tasksController.setCurrentTask GG.tasksController.objectAt parseInt(taskPath[2])-1
            Ember.run ->
              GG.universeView.setCurrentView 'baseline'
            if taskPath[2]
              GG.statemanager.transitionTo 'inTask'
            else
              GG.statemanager.transitionTo 'inTaskList'
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

  loggingOut: Ember.State.create
    enter: ->
      GG.sessionController.logoutPortal()

  inWorld: GG.StateInWorld,

  inTown: GG.StateInTown,

  inTaskList: GG.StateInTaskList,

  inTask: GG.StateInTask
