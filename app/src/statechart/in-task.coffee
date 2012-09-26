GG.StateInTask = Ember.State.extend

  initialState: 'showingBreeder'

  showingBreeder: Ember.State.create
    initialState: 'working'

    enter: ->
      $('#breeding-apparatus').animate({"left":"0px"},1200,'easeOutCubic')
      GG.cyclesController.reset()

    exit: ->
      # clear offspring
      GG.breedingController.set 'child', null
      GG.offspringController.set 'content', []

      $('#breeding-apparatus').animate({"left":"3000px"},1200,'easeInCubic')
      setTimeout =>
        # hide the breeding apparatus
        # clear selected parents and parent pools
        GG.parentController.reset()
      , 1200



    parentSelected: (manager, parent) ->
      sex = parent.get('sex')
      whichSelection = if sex is GG.FEMALE then 'selectedMother' else 'selectedFather'
      GG.parentController.set whichSelection, parent

      controller = if sex is GG.FEMALE then GG.motherPoolController else GG.fatherPoolController
      controller.set('hidden', false)

      GG.logController.logEvent GG.Events.SELECTED_PARENT,
        alleles: parent.get('biologicaOrganism.alleles')
        sex: parent.get('sex')

    parentRemoved: (manager, parent) ->
      whichSelection = if parent.get('sex') is GG.FEMALE then 'selectedMother' else 'selectedFather'
      if GG.parentController.get(whichSelection) == parent
        GG.parentController.set whichSelection, null
      GG.parentController.removeObject parent

      controller = if sex is GG.FEMALE then GG.motherPoolController else GG.fatherPoolController
      controller.set('hidden', false)

      GG.logController.logEvent GG.Events.REMOVED_PARENT,
        alleles: parent.get('biologicaOrganism.alleles')
        sex: parent.get('sex')

    offspringSelected: (manager, child) ->
      if GG.parentController.hasRoom child
        # add it to the parentController, and remove it from the offspringController
        GG.offspringController.removeObject child
        GG.parentController.pushObject child
        GG.userController.addReputation -1

        GG.logController.logEvent GG.Events.SELECTED_OFFSPRING,
          alleles: child.get('biologicaOrganism.alleles')
          sex: child.get('sex')

    breedDrake: ->
      GG.breedingController.breedDrake()

    startFatherMeiosis: ->
      if GG.breedingController.get 'father'
        GG.animateMeiosis '#parent-fathers-pool-container'

    startMotherMeiosis: ->
      if GG.breedingController.get 'mother'
        GG.animateMeiosis '#parent-mothers-pool-container'

    decrementCycles: (manager, amt) ->
      GG.cyclesController.decrement(amt)

    resetCounter: ->
      GG.cyclesController.reset()

    checkForTaskCompletion: (manager) ->
      if GG.tasksController.isCurrentTaskComplete()
        manager.send 'completeTask'

    completeTask: ->
      GG.tasksController.completeCurrentTask()
      GG.tasksController.showTaskCompletion()

    working: Ember.State.create