GG.StateInTask = Ember.State.extend

  initialState: 'showingBreeder'

  showingBreeder: Ember.State.create
    initialState: 'parentSelect'

    breedType: 'direct'  # direct/meiosis

    enter: ->
      $('#breeding-apparatus').animate({"left":"0px"},1200,'easeOutCubic')
      GG.cyclesController.reset()

    exit: ->
      # clear offspring
      GG.breedingController.set 'child', null
      GG.offspringController.set 'content', null

      $("#breeder").animate({left: 0},400,"easeOutCubic")
      $('#breed-controls').animate({left: 742},400,'easeOutCubic')
      $('#breeding-apparatus').animate({"left":"3000px"},1200,'easeInCubic')
      setTimeout =>
        # hide the breeding apparatus
        # clear selected parents and parent pools
        GG.parentController.reset()
      , 1200

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

    parentSelect: Ember.State.create

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
        controller.set('hidden', true)

        GG.logController.logEvent GG.Events.REMOVED_PARENT,
          alleles: parent.get('biologicaOrganism.alleles')
          sex: parent.get('sex')

      breedDrake: (manager) ->
        if GG.motherPoolController.get('selected') && GG.fatherPoolController.get('selected')
          manager.transitionTo 'breeding'

      offspringSelected: (manager, child) ->
        if GG.parentController.hasRoom child
          # add it to the parentController, and remove it from the offspringController
          GG.offspringController.set 'content', null
          GG.parentController.pushObject child
          GG.userController.addReputation -1

          GG.logController.logEvent GG.Events.SELECTED_OFFSPRING,
            alleles: child.get('biologicaOrganism.alleles')
            sex: child.get('sex')

      startFatherMeiosis: ->
        if GG.breedingController.get 'father'
          GG.animateMeiosis '#parent-fathers-pool-container'

      startMotherMeiosis: ->
        if GG.breedingController.get 'mother'
          GG.animateMeiosis '#parent-mothers-pool-container'

    breeding: Ember.State.create
      setup: (manager) ->
        $('#breed-controls').animate({left: 525},400,'easeOutCubic')
        $("#breeder").animate({left: -522},500,"easeOutCubic")
        setTimeout ->
          GG.motherPoolController.set('hidden', true)
          GG.fatherPoolController.set('hidden', true)
        , 1000
        setTimeout ->
          manager.send 'breedDrake'
        , 1200

      breedDrake: ->
        GG.breedingController.breedDrake()