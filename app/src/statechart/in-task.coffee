GG.StateInTask = Ember.State.extend

  initialState: 'showingBreeder'

  goToTown: (manager) ->
    manager.transitionTo 'inTown'

  goToWorld: (manager) ->
    manager.transitionTo 'inWorld'

  showingBreeder: Ember.State.create
    initialState: 'parentSelect'

    enter: ->
      $('#task-list').hide()
      if not GG.baselineController.get 'isBaseline'
        $('#breeding-apparatus').animate {"left":"20px"},1200,'easeOutCubic', ->
          GG.breedingController.set 'isShowingBreeder', true
          GG.breedingController.set 'isShowingBreeder2', true
          GG.tutorialMessageController.showTargetTutorial()
      else
        $('#breeding-apparatus').css {"left":"20px"}
        GG.breedingController.set 'isShowingBreeder', true
        GG.tutorialMessageController.showTargetTutorial()
      GG.cyclesController.reset()
      GG.reputationController.reset()
      if (GG.userController.get('controlMeiosis') and GG.tasksController.get('meiosisControlEnabled'))
        breedType = GG.BREED_CONTROLLED
      else
        breedType = GG.BREED_AUTOMATED
      GG.breedingController.set 'breedType', breedType

    exit: (manager) ->
      manager.send 'hideLeaderboard'
      GG.breedingController.set 'isShowingBreeder', false
      GG.breedingController.set 'isShowingBreeder2', false
      # clear offspring
      GG.breedingController.set 'child', null
      GG.offspringController.set 'content', null

      $("#breeder").animate({left: 0},400,"easeOutCubic")
      $('#breed-controls').animate({left: 650},400,'easeOutCubic')
      $('#breeding-apparatus').animate({"left":"3000px"},1200,'easeInCubic')
      setTimeout =>
        # hide the breeding apparatus
        # clear selected parents and parent pools
        GG.parentController.reset()
      , 1200

    decrementCycles: (manager, amt) ->
      if GG.baselineController.get 'isBaseline'
        GG.cyclesController.increment(amt)
      else
        GG.cyclesController.decrement(amt)

    resetCounter: ->
      GG.cyclesController.reset()

    checkForTaskCompletion: (manager) ->
      child = GG.offspringController.get 'content'
      success = false
      if GG.tasksController.isCurrentTaskComplete()
        manager.send 'completeTask'
        success = true
      else if GG.tasksController.get('currentTask.cyclesRemaining') is 0 and
            GG.obstacleCourseController.get('hasObstacleCourse')
          # log the drake submission
          # also log the task as "completed"
          manager.send 'completeTask'
          # success should be false, probably, but leave it as true so we don't mess up the tournament
          success = true
      else
        GG.tasksController.showTaskNonCompletion()
      GG.logController.logEvent GG.Events.SUBMITTED_OFFSPRING,
        alleles: child.get('biologicaOrganism.alleles')
        sex: child.get('sex')
        success: success

    completeTask: (manager) ->
      $('#task-reputation-available').hide()
      $('#task-reputation-best').hide()
      GG.tasksController.completeCurrentTask()
      if GG.obstacleCourseController.get('hasObstacleCourse')
        # manager.transitionTo 'obstacleCourse'
        GG.tasksController.showTaskCompletion()
      else
        GG.tasksController.showTaskCompletion()

    parentSelect: Ember.State.create

      setup: ->
        $('#progress-bar').switchClass($('#progress-bar').attr('class'),"selecting",1000)
        GG.offspringController.set 'content', null
        $('#target').show()
        whosSelected = GG.parentController.get 'whosSelected'
        $('#chromosome-labels').attr('class', whosSelected).show()
        $('#breed-controls').animate({left: 650},600,'easeOutCubic')
        $("#breeder").animate({left: 0},800,"easeOutCubic")
        $('#task-reputation-available').show()
        $('#task-reputation-best').show()
        $('#chromosome-labels-meiosis').hide()
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

        parentName = if sex is GG.FEMALE then "mother" else "father"
        GG.tutorialMessageController.showFirstDrakeSelectionTutorial parentName
        Ember.run.next this, ->
          # after bindings have updated
          GG.tutorialMessageController.showBreedButtonTutorial()
          GG.tutorialMessageController.showMeiosisControlTutorial()

        whosSelected = GG.parentController.get 'whosSelected'
        $('#chromosome-labels').attr('class', whosSelected).show()

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

        whosSelected = GG.parentController.get 'whosSelected'
        $('#chromosome-labels').attr('class', whosSelected).show()

        GG.logController.logEvent GG.Events.REMOVED_PARENT,
          alleles: parent.get('biologicaOrganism.alleles')
          sex: sex

      breedDrake: (manager) ->
        if GG.motherPoolController.get('selected') && GG.fatherPoolController.get('selected')
          GG.logController.logEvent GG.Events.BREED_BUTTON_CLICKED, {duringMeiosis: false}
          manager.transitionTo 'animatingMeiosis'

      startFatherMeiosis: ->
        if GG.breedingController.get 'father'
          GG.animateMeiosis '#parent-fathers-pool-container'

      startMotherMeiosis: ->
        if GG.breedingController.get 'mother'
          GG.animateMeiosis '#parent-mothers-pool-container'

      toggleBreedType: ->
        if GG.tasksController.get 'meiosisControlEnabled'
          GG.breedingController.toggleBreedType()

    animatingMeiosis: Ember.State.create
      firstTime: true
      setup: (manager)->
        @set('firstTime', true)
        GG.meiosisController.set('inAnimation', true)
        $('#target').hide()
        $('#breed-controls').animate({left: 474},400,'easeOutCubic')
        $("#breeder").animate({left: -459},500,"easeOutCubic")
        # hide the offspring pool
        $("#offspring-panel").animate({left: 400},500,"easeOutCubic")
        $("#offspring-pool .chromosome-panel").hide()
        scale = GG.MeiosisAnimation.get 'timeScale'
        setTimeout ->
          $('#chromosome-labels').hide()
          GG.motherPoolController.set('hidden', true)
          GG.fatherPoolController.set('hidden', true)
        , GG.MeiosisAnimation.scale(600)
        setTimeout ->
          manager.send 'animate'
        , GG.MeiosisAnimation.scale(800)

      animate: (manager)->
        scale = GG.MeiosisAnimation.get 'timeScale'
        firstTime = @get 'firstTime'
        @set('firstTime', false)
        delay = if firstTime then GG.MeiosisAnimation.scale(2000) else 1

        if GG.cyclesController.get('cycles') <= 0
          GG.reputationController.subtractReputation(GG.actionCostsController.getCost('extraBreedCycle'), GG.Events.BRED_WITH_EXTRA_CYCLE)
        currentProgClass = $('#progress-bar').attr('class')
        $('#progress-bar').switchClass(currentProgClass,"breeding",2000) unless currentProgClass is "breeding"
        manager.send 'decrementCycles', 1
        GG.breedingController.set 'childSavedToParents', false
        $('#meiosis-container').removeClass('hidden')
        $("#offspring-pool .chromosome-panel").hide()
        setTimeout ->
          GG.tutorialMessageController.showMeiosisTutorial ->
            GG.meiosisController.animate ->
              setTimeout ->
                GG.meiosisController.resetAnimation()
              , 500
              manager.transitionTo 'breeding'
        , delay

      selectingCrossoverCallback: null
      doneSelectingCrossover: (manager, parent) ->
        callback = @get('selectingCrossoverCallback')
        $('#' + parent.get('elementId') + " .crossoverSelection").addClass('hidden')
        $('#' + parent.get('elementId') + " .crossoverPoint").removeClass('clickable')
        $('#' + parent.get('elementId') + " .crossoverPoint").addClass('hidden')
        GG.meiosisController.set('crossoverSelected', false)
        GG.meiosisController.set('selectedCrossover', null)
        if callback?
          callback.call()
        else
          console.log("no callback specified for doneSelectingCrossover!")

      selectingCrossover: (manager, context) ->
        @set('selectingCrossoverCallback', context.callback)
        selector = '#' + context.elementId + ' .crossoverSelection'
        $(selector).removeClass('hidden')
        selector = '#' + context.elementId + ' .crossoverPoint'
        Ember.run.next ->
          # do this in the next run loop, since earlier we switched from using the drake
          # to using gametes, so the views need time to adjust themselves
          $(selector).addClass('clickable')
          $(selector).removeClass('hidden')

      selectingChromatidsCallback: null
      doneSelectingChromatids: (manager, parent) ->
        callback = @get('selectingChromatidsCallback')
        GG.meiosisController.set('chromosomeSelected', false)
        GG.meiosisController.set('selectedChromosomes', { father: {}, mother: {}})
        if callback?
          $('#' + parent.get('elementId') + " .chromatidSelection").addClass('hidden')
          callback.call()
        else
          console.log("no callback specified for doneSelectingChromatids!")

      selectingChromatids: (manager, context) ->
        @set('selectingChromatidsCallback', context.callback)
        selector = '#' + context.elementId + ' .chromatidSelection'
        $(selector).removeClass('hidden')
        GG.tutorialMessageController.showMeiosisGenderTutorial()

      deselectedChromosome: (manager, chromoView)->
        GG.meiosisController.deselectChromosome(chromoView)
        GG.logController.logEvent GG.Events.DESELECTED_CHROMOSOME,
          drake: if chromoView.get('content.female') then "mother" else "father"
          chromosome: chromoView.get('chromo')
          side: chromoView.get('side')
          sister: chromoView.get('sister')
          visibleAlleles: chromoView.get('visibleGamete')
          hiddenAlleles: chromoView.get('hiddenGamete')
      selectedChromosome: (manager, chromoView)->
        GG.meiosisController.selectChromosome(chromoView)
        GG.logController.logEvent GG.Events.CHOSE_CHROMOSOME,
          drake: if chromoView.get('content.female') then "mother" else "father"
          chromosome: chromoView.get('chromo')
          side: chromoView.get('side')
          sister: chromoView.get('sister')
          visibleAlleles: chromoView.get('visibleGamete')
          hiddenAlleles: chromoView.get('hiddenGamete')

      selectedCrossover: (manager, context)->
        GG.meiosisController.selectCrossover(context)

      breedDrake: (manager)->
        if GG.meiosisController.get('canBreedDuringAnimation')
          GG.logController.logEvent GG.Events.BREED_BUTTON_CLICKED,
            duringMeiosis: true
            parent: GG.MeiosisAnimation.get('parent')
            stage: GG.MeiosisAnimation.get('stage')
          # If the breed button gets clicked while we're animating,
          # reset the animation and go again
          GG.meiosisController.resetAnimation()
          setTimeout ->
            manager.send 'animate'
          , 200

      selectParents: (manager) ->
        GG.meiosisController.resetAnimation()
        $('#meiosis-container').addClass('hidden')
        setTimeout ->
          manager.transitionTo 'parentSelect'
        , 200

    breeding: Ember.State.create
      setup: (manager) ->
        setTimeout ->
          manager.send 'breedDrakeInternal'
        , 200
        setTimeout ->
          container = $('#meiosis-container')
          container.animate {opacity: 0}, 100, 'easeInQuad', ->
            container.addClass('hidden')
            container.css({opacity: 1})
        , 100

      breedDrake: (manager)->
        GG.logController.logEvent GG.Events.BREED_BUTTON_CLICKED, {duringMeiosis: false}
        manager.transitionTo 'animatingMeiosis'

      breedDrakeInternal: ->
        GG.breedingController.breedDrake()

      showOffspring: (manager) ->
        $('#progress-bar').switchClass($('#progress-bar').attr('class'),"results",1000)
        $("#offspring-pool .chromosome-panel").show()
        $('#offspring-panel').animate({left: -76},300,"easeOutCubic")
        GG.tutorialMessageController.showFirstOffspringCreatedTutorial()
        if GG.tasksController.get('currentTask.cyclesRemaining') is 0 and
            GG.obstacleCourseController.get('hasObstacleCourse')
          manager.send 'checkForTaskCompletion'

      submitOffspring: (manager) ->
        manager.send 'checkForTaskCompletion'

      freeOffspring: ->
        child = GG.offspringController.get 'content'
        GG.offspringController.set 'content', null
        GG.logController.logEvent GG.Events.FREED_OFFSPRING,
          alleles: child.get('biologicaOrganism.alleles')
          sex: child.get('sex')

      saveOffspring: (manager) ->
        return if GG.breedingController.get 'childSavedToParents'
        child = GG.offspringController.get 'content'
        if GG.parentController.hasRoom child
          GG.breedingController.set 'childSavedToParents', true
          GG.parentController.pushObject child

          GG.logController.logEvent GG.Events.KEPT_OFFSPRING,
            alleles: child.get('biologicaOrganism.alleles')
            sex: child.get('sex')

      selectParents: (manager) ->
        manager.transitionTo 'parentSelect'

      toggleBreedType: ->
        GG.breedingController.toggleBreedType()

    obstacleCourse: Ember.State.create
      enter: (manager)->
        $('#progress-bar').switchClass($('#progress-bar').attr('class'),"obstacle-results",1000)
        GG.obstacleCourseController.showInfoDialog()

      startCourse: (manager)->
        GG.obstacleCourseController.set('dialogVisible', true)
        $('#obstacle-course-dialog').show()
        $('#modal-backdrop-fade').show()

        GG.obstacleCourseController.set 'currentObstacleIndex', 0
        numObstacles = GG.obstacleCourseController.get('obstacles').length

        startObstacle = ->
          if GG.obstacleCourseController.didPassObstacle()
            if GG.cyclesController.get('cycles') then state = "successLarge"
            else state = "successSmall"
          else
            state = "fail"

          GG.obstacleCourseController.get('drake').set 'obstacleState', state
          setTimeout finishObstacle, 1900

        finishObstacle = ->
          GG.obstacleCourseController.get('drake').set('obstacleState', null)
          index = GG.obstacleCourseController.get 'currentObstacleIndex'
          $($(".obstacle-time-breakdown .revealable")[index]).show()
          if GG.obstacleCourseController.didPassObstacle()
            $(".obstacle").hide()
            $(".obstacle.after").show()

          setTimeout showNextObstacle, 2800

        showNextObstacle = ->
          index = GG.obstacleCourseController.get 'currentObstacleIndex'
          if index < numObstacles - 1
            GG.obstacleCourseController.goToNextObstacle()
            startObstacle()
          else
            setTimeout ->
              $(".obstacle-time-breakdown .align-right").show()
              setTimeout ->
                $("#obstacle-course-dialog-content .revealable").show()
              , 500
            , 100

        startObstacle()

      exit: (manager)->
        GG.obstacleCourseController.set('dialogVisible', false)
        $('#obstacle-course-dialog').hide()
        $('#modal-backdrop-fade').hide()
