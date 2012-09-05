###
STATES:

  inTask
    showingBreeder
###

GG.statemanager = Ember.StateManager.create
  initialState: 'loading'
  params: {}

  loading: Ember.State.create

  loggingIn: Ember.State.create
    enter: ->
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

  inWorld: Ember.State.create
    initialState: 'townsWaiting'

    enter: ->
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
          GG.universeView.set 'currentView', GG.universeView.get 'world'
          currentTown = GG.townsController.get('currentTown')
          if currentTown?
            setTimeout ->
              $('#world').rotate(currentTown.get('position') + "deg")
            , 10

      if GG.statemanager.get('params').learner?
        obs = ->
          GG.userController.removeObserver('loaded', obs)
          loadGame()
        GG.userController.addObserver('loaded', obs)
        GG.userController.set('learnerId', GG.statemanager.get('params').learner)
      else
        loadGame()

    townsWaiting: Ember.State.create
      spriteAnimation: null
      townSelected: (manager, town) ->
        if town.get('enabled')
          prevTown = GG.townsController.get('currentTown')
          changed = GG.townsController.setCurrentTown(town)
          navigateTime = 100
          if changed and prevTown?
            navigateTime = 4000
            spriteFrame = 1
            animateSprite = ->
              spriteFrame++
              top = 72 * (spriteFrame % 8)
              $('.dragon').css('backgroundPosition','-0px -'+top+'px')
            spriteAnimation = setInterval(animateSprite,50)
            if (prevTown.get('position') < town.get('position'))
              $("#dragon-right").attr("id","dragon-left")
            else
              $("#dragon-left").attr("id","dragon-right")
            # dragon take off, spin the world, land if we're not already at that town
            $('.dragon').animate({left: "-=20px", top: "-=30px"}, {duration: 400, complete: ->
              $('#world').animate({rotate: town.get('position')}, {duration: navigateTime, complete: ->
                $('.dragon').animate({left: "+=20px", top: "+=30px"}, {duration: 400, complete: ->
                  clearInterval(spriteAnimation)
                  spriteFrame = 1
                  animateSprite()
                })
              })
            })
          setTimeout =>
            GG.statemanager.goToState 'inTown'
          , navigateTime+1200


  inTown: Ember.State.create
    initialState: 'npcsWaiting'

    enter: ->
      GG.universeView.set 'currentView', GG.universeView.get 'town'

    npcsWaiting: Ember.State.create
      enter: ->
        task.set('showQuestionBubble', false) for task in GG.tasksController.content
        task.set('showSpeechBubble', false) for task in GG.tasksController.content

        firstIncompleteTask = null
        for task in GG.tasksController.content
          firstIncompleteTask = task unless task.get('completed') or firstIncompleteTask?

        # Go to world view if all tasks are complete?
        # TODO Add some sort of transition with dialog
        if firstIncompleteTask?
          setTimeout =>
            firstIncompleteTask.set('showQuestionBubble', true)
          , 1000
        else
          GG.townsController.completeCurrentTown()
          setTimeout =>
            GG.statemanager.goToState('inWorld')
          , 1000


      npcSelected: (manager, task) ->
        GG.tasksController.showTaskDescription task
        GG.statemanager.goToState 'npcShowingTask'

    npcShowingTask: Ember.State.create
      accept: (manager, task) ->
        GG.tasksController.taskAccepted task
      decline: ->
        GG.statemanager.goToState 'npcsWaiting'


  inTask: Ember.State.create
    initialState: 'showingBreeder'

    showingBreeder: Ember.State.create
      initialState: 'working'

      enter: ->
        $('#breeding-apparatus').animate({"top":"0px"},1200,'easeOutBounce')

      exit: ->
        # Reset breeding apparatus
        # pull in the wings of the apparatus
        @toggleMotherPool() if @get 'mothersExpanded'
        @toggleFatherPool() if @get 'fathersExpanded'

        # clear selected parents and parent pools
        GG.parentController.reset()

        # clear offspring
        GG.breedingController.set 'child', null
        GG.offspringController.set 'content', []

        # reset move counter
        GG.moveController.reset()

        # hide the breeding apparatus
        setTimeout =>
          $('#breeding-apparatus').animate({"top":"-850px"},1200,'easeOutBounce')
        , 1000

      parentSelected: (manager, parent) ->
        whichSelection = if parent.get('sex') is GG.FEMALE then 'selectedMother' else 'selectedFather'
        GG.parentController.set whichSelection, parent

        GG.logController.logEvent GG.Events.SELECTED_PARENT,
          alleles: parent.getPath('biologicaOrganism.alleles')
          sex: parent.get('sex')

      parentRemoved: (manager, parent) ->
        whichSelection = if parent.get('sex') is GG.FEMALE then 'selectedMother' else 'selectedFather'
        if GG.parentController.get(whichSelection) == parent
          GG.parentController.set whichSelection, null
        GG.parentController.removeObject parent

        GG.logController.logEvent GG.Events.REMOVED_PARENT,
          alleles: parent.getPath('biologicaOrganism.alleles')
          sex: parent.get('sex')

      offspringSelected: (manager, child) ->
        if GG.parentController.hasRoom child
          # add it to the parentController, and remove it from the offspringController
          GG.offspringController.removeObject child
          GG.parentController.pushObject child
          GG.moveController.increment()

          GG.logController.logEvent GG.Events.SELECTED_OFFSPRING,
            alleles: child.getPath('biologicaOrganism.alleles')
            sex: child.get('sex')

      breedDrake: ->
        GG.breedingController.breedDrake()

      mothersExpanded: false
      toggleMotherPool: ->
        motherContainer = $('#parent-mothers-pool-container')
        motherPool = $('#parent-mothers-pool-container .parent-pool')
        motherExpander = $('#parent-mothers-pool-container .expander')
        if @get 'mothersExpanded'
          motherContainer.animate({left: 595},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -0px')
            GG.motherPoolController.set('hidden', true)
          })
        else
          motherContainer.animate({left: 721},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -15px')
            GG.motherPoolController.set('hidden', false)
          })

        @set 'mothersExpanded', !@get 'mothersExpanded'

      fathersExpanded: false
      toggleFatherPool: ->
        fatherContainer = $('#parent-fathers-pool-container')
        fatherPool = $('#parent-fathers-pool-container .parent-pool')
        fatherExpander = $('#parent-fathers-pool-container .expander')
        if not @get 'fathersExpanded'
          fatherContainer.animate({left: 1},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -0px')
            GG.fatherPoolController.set('hidden', false)
          })
        else
          fatherContainer.animate({left: 135},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -15px')
            GG.fatherPoolController.set('hidden', true)
          })

        @set 'fathersExpanded', !@get 'fathersExpanded'

      startFatherMeiosis: ->
        if GG.breedingController.get 'father'
          GG.animateMeiosis '#parent-fathers-pool-container'

      startMotherMeiosis: ->
        if GG.breedingController.get 'mother'
          GG.animateMeiosis '#parent-mothers-pool-container'

      incrementCounter: ->
        GG.moveController.increment()

      resetCounter: ->
        GG.moveController.reset()

      checkForTaskCompletion: ->
        if GG.tasksController.isCurrentTaskComplete()
          GG.statemanager.goToState 'taskCompleted'

      working: Ember.State.create
      taskCompleted: Ember.State.create
        enter: ->
          # TODO Show a congratulations dialog!
          GG.tasksController.showTaskCompletion(GG.tasksController.get 'currentTask')
