GG.StateInTask = Ember.State.extend

  initialState: 'showingBreeder'

  showingBreeder: Ember.State.create
    initialState: 'parentSelect'

    breedType: 'direct'  # direct/meiosis

    enter: ->
      $('#breeding-apparatus').animate({"left":"-17px"},1200,'easeOutCubic')
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
      child = GG.offspringController.get 'content'
      success = false
      if GG.tasksController.isCurrentTaskComplete()
        manager.send 'completeTask'
        success = true
      else
        GG.tasksController.showTaskNonCompletion()
      GG.logController.logEvent GG.Events.SUBMITTED_OFFSPRING,
        alleles: child.get('biologicaOrganism.alleles')
        sex: child.get('sex')
        success: success

    completeTask: ->
      GG.tasksController.completeCurrentTask()
      GG.tasksController.showTaskCompletion()

    parentSelect: Ember.State.create

      setup: ->
        GG.offspringController.set 'content', null
        $('#breed-controls').animate({left: 742},600,'easeOutCubic')
        $("#breeder").animate({left: 0},800,"easeOutCubic")
        setTimeout ->
          GG.motherPoolController.set('hidden', !GG.motherPoolController.selected)
          GG.fatherPoolController.set('hidden', !GG.fatherPoolController.selected)
        , 600

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
        sex = parent.get('sex')
        whichSelection = if sex is GG.FEMALE then 'selectedMother' else 'selectedFather'
        if GG.parentController.get(whichSelection) == parent
          GG.parentController.set whichSelection, null
          controller = if sex is GG.FEMALE then GG.motherPoolController else GG.fatherPoolController
          controller.set('hidden', true)
        GG.parentController.removeObject parent

        GG.logController.logEvent GG.Events.REMOVED_PARENT,
          alleles: parent.get('biologicaOrganism.alleles')
          sex: sex

      breedDrake: (manager) ->
        if GG.motherPoolController.get('selected') && GG.fatherPoolController.get('selected')
          manager.transitionTo 'animatingMeiosis'

      startFatherMeiosis: ->
        if GG.breedingController.get 'father'
          GG.animateMeiosis '#parent-fathers-pool-container'

      startMotherMeiosis: ->
        if GG.breedingController.get 'mother'
          GG.animateMeiosis '#parent-mothers-pool-container'

    animatingMeiosis: Ember.State.create
      setup: (manager)->
        # hide the offspring pool
        $('#breed-controls').animate({left: 525},400,'easeOutCubic')
        $("#breeder").animate({left: -522},500,"easeOutCubic")
        $('#offspring-pool').hide()
        setTimeout ->
          GG.motherPoolController.set('hidden', true)
          GG.fatherPoolController.set('hidden', true)
        , 600
        setTimeout ->
          manager.send 'animate'
        , 800

      animate: (manager)->
        $('#meiosis-container').removeClass('hidden')
        GG.meiosisController.animate ->
          setTimeout ->
            GG.meiosisController.resetAnimation()
          , 500
          manager.transitionTo 'breeding'

    breeding: Ember.State.create
      setup: (manager) ->
        setTimeout ->
          manager.send 'breedDrakeInternal'
        , 200
        setTimeout ->
          $('#offspring-pool').show()
          $('#meiosis-container').addClass('hidden')
        , 400

      breedDrake: (manager)->
        manager.transitionTo 'animatingMeiosis'

      breedDrakeInternal: ->
        GG.breedingController.breedDrake()

      submitOffspring: (manager) ->
        manager.send 'checkForTaskCompletion'

      freeOffspring: ->
        child = GG.offspringController.get 'content'
        GG.offspringController.set 'content', null
        GG.logController.logEvent GG.Events.FREED_OFFSPRING,
          alleles: child.get('biologicaOrganism.alleles')
          sex: child.get('sex')

      saveOffspring: (manager) ->
        #offspringSelected: (manager, child) ->
        child = GG.offspringController.get 'content'
        if GG.parentController.hasRoom child
          # add it to the parentController, and remove it from the offspringController
          GG.offspringController.set 'content', null
          GG.parentController.pushObject child
          GG.userController.addReputation -1

          GG.logController.logEvent GG.Events.KEPT_OFFSPRING,
            alleles: child.get('biologicaOrganism.alleles')
            sex: child.get('sex')

      selectParents: (manager) ->
        manager.transitionTo 'parentSelect'

    obstacleCourse: Ember.State.create
      enter: (manager)->
        GG.obstacleCourseController.set('hidden', false)
        $('#breeder').hide()
        $('#breed-top-bar').hide()

      exit: (manager)->
        GG.obstacleCourseController.set('hidden', true)
        $('#breeder').show()
        $('#breed-top-bar').show()
