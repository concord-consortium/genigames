###
STATES:

  inTask
    showingBreeder
###

GG.statemanager = Ember.StateManager.create
  initialState: 'loading'

  loading: Ember.State.create

  inTown: Ember.State.create
    initialState: 'npcsWaiting'

    npcsWaiting: Ember.State.create
      enter: ->
        task.set('showQuestionBubble', false) for task in GG.tasksController.content
        task.set('showSpeechBubble', false) for task in GG.tasksController.content

        firstTask = GG.tasksController.get 'firstObject'
        setTimeout =>
          firstTask.set('showQuestionBubble', true)
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
      enter: ->
        $('#breeding-apparatus').animate({"top":"0px"},1200,'easeOutBounce')

      parentSelected: (manager, parent) ->
        whichSelection = if parent.get('sex') is GG.FEMALE then 'selectedMother' else 'selectedFather'
        GG.parentController.set whichSelection, parent

        GG.logController.logEvent GG.Events.SELECTED_PARENT,
          alleles: parent.getPath('biologicaOrganism.alleles')
          sex: parent.get('sex')

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
        if @get 'fathersExpanded'
          fatherContainer.animate({left: 135},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -15px')
            GG.fatherPoolController.set('hidden', true)
          })
        else
          fatherContainer.animate({left: 1},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -0px')
            GG.fatherPoolController.set('hidden', false)
          })

        @set 'fathersExpanded', !@get 'fathersExpanded'

      incrementCounter: ->
        GG.moveController.increment()

      resetCounter: ->
        GG.moveController.reset()

