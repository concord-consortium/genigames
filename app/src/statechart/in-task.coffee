GG.StateInTask = Ember.State.extend

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
      GG.cyclesController.reset()

      # hide the breeding apparatus
      setTimeout =>
        $('#breeding-apparatus').animate({"top":"-850px"},1200,'easeOutBounce')
      , 1000

    parentSelected: (manager, parent) ->
      sex = parent.get('sex')
      whichSelection = if sex is GG.FEMALE then 'selectedMother' else 'selectedFather'
      GG.parentController.set whichSelection, parent

      if sex is GG.FEMALE and not @mothersExpanded
        manager.send('toggleMotherPool')
      else if sex is GG.MALE and not @fathersExpanded
        manager.send('toggleFatherPool')

      GG.logController.logEvent GG.Events.SELECTED_PARENT,
        alleles: parent.get('biologicaOrganism.alleles')
        sex: parent.get('sex')

    parentRemoved: (manager, parent) ->
      whichSelection = if parent.get('sex') is GG.FEMALE then 'selectedMother' else 'selectedFather'
      if GG.parentController.get(whichSelection) == parent
        GG.parentController.set whichSelection, null
      GG.parentController.removeObject parent

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