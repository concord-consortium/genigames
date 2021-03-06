GG.StateInTask = Ember.State.extend

  initialState: 'showingBreeder'

  goToTown: (manager) ->
    manager.transitionTo 'inTown'

  goToWorld: (manager) ->
    manager.transitionTo 'inWorld'

  showingBreeder: Ember.State.create
    initialState: 'powerUp'

    enter: (manager) ->
      manager.send 'hideLeaderboard'
      GG.hideInfoDialogs()
      $('#task-list').hide()
      $(".characteristic").removeClass("selected")
      if not GG.baselineController.get 'isBaseline'
        $('#breeding-apparatus').animate {"left":"20px"},1200,'easeOutCubic', ->
          GG.breedingController.set 'isShowingBreeder', true
          GG.breedingController.set 'isShowingBreeder2', true
          GG.tutorialMessageController.showTraitBarTutorial()
      else
        $('#breeding-apparatus').css {"left":"20px"}
        GG.breedingController.set 'isShowingBreeder', true
        GG.tutorialMessageController.showTraitBarTutorial()
      GG.cyclesController.reset()
      GG.reputationController.reset()
      if GG.tasksController.get('meiosisControlEnabled')
        breedType = GG.BREED_CONTROLLED
      else
        breedType = GG.BREED_AUTOMATED
      GG.breedingController.set 'breedType', breedType

    exit: (manager) ->
      manager.send 'hideLeaderboard'
      GG.hideInfoDialogs()
      GG.breedingController.set 'isShowingBreeder', false
      GG.breedingController.set 'isShowingBreeder2', false
      # clear offspring
      GG.breedingController.set 'child', null
      GG.offspringController.set 'content', null

      $("#breeder").animate({left: 0},400,"easeOutCubic")
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
        success = true
      GG.logController.logEvent GG.Events.SUBMITTED_OFFSPRING,
        alleles: child.get('biologicaOrganism.alleles')
        sex: child.get('sex')
        success: success
      manager.send 'completeTask', success

    completeTask: (manager, success) ->
      $('#task-reputation-available').hide()
      $('#task-reputation-best').hide()
      if success
        GG.tasksController.completeCurrentTask()
      GG.tasksController.showTaskCompletion(success)

    selectTrait: ->
      # do nothing

    powerUp: Ember.State.create
      powerups: []
      displayed: false
      enter: (manager)->
        powerups = GG.tasksController.get('currentTask.powerups')
        @set('powerups', powerups || [])
        observer = ->
          GG.breedingController.removeObserver observer
          if GG.breedingController.get 'isShowingBreeder'
            manager.send 'displayNextPowerup'
        if GG.breedingController.get 'isShowingBreeder'
          observer()
        else
          GG.breedingController.addObserver 'isShowingBreeder', observer

      displayNextPowerup: (manager)->
        return if @get('displayed')
        powerups = @get('powerups')
        if powerups && powerups.length > 0
          @set 'displayed', true
          powerup = powerups[0]
          @set('powerups', powerups.slice(1))
          if GG.powerUpController.hasPowerup(powerup.name)
            # Already unlocked this
            setTimeout =>
              @set 'displayed', false
              manager.send 'displayNextPowerup'
            , 1
          else
            # Display powerup
            GG.powerUpController.set('powerup', powerup)
            GG.powerUpController.unlockPowerup(powerup)
            $('#modal-backdrop-fade').fadeIn(500)
            $('#powerup-popup').fadeIn(500)
        else
          setTimeout =>
            @set 'displayed', false
            manager.transitionTo 'parentSelect'
          , 1

      dismissPowerupPopup: (manager)->
        return unless @get('displayed')
        @set 'displayed', false
        # Hide dialog, then display the next powerup, if any
        $('#modal-backdrop-fade').fadeOut(500)
        $('#powerup-popup').fadeOut(500)
        setTimeout ->
          manager.send 'displayNextPowerup'
        , 505

    parentSelect: Ember.State.create

      setup: ->
        GG.offspringController.set 'content', null
        whosSelected = GG.parentController.get 'whosSelected'
        $('#chromosome-labels').attr('class', whosSelected).show()
        $("#breeder").animate({left: 0},800,"easeOutCubic")
        $('#task-reputation-available').show()
        $('#task-reputation-best').show()
        $('#chromosome-labels-meiosis').removeClass('mother').hide()
        $('#chromosome-labels-meiosis-long').hide()
        $('#meiosis-container').addClass('hidden');
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
        GG.hideInfoDialogs()
        if GG.motherPoolController.get('selected') && GG.fatherPoolController.get('selected')
          GG.logController.logEvent GG.Events.BREED_BUTTON_CLICKED, {duringMeiosis: false}
          manager.transitionTo 'animatingMeiosis'

      startFatherMeiosis: ->
        if GG.breedingController.get 'father'
          GG.animateMeiosis '#parent-fathers-pool-container'

      startMotherMeiosis: ->
        if GG.breedingController.get 'mother'
          GG.animateMeiosis '#parent-mothers-pool-container'

      waitForTraitSelection: (manager) ->
        manager.transitionTo 'waitingForTraitSelection'


      # These tutorial states are substates of parentSelect
      # waitingForTraitSelection is entered explicitly by the tutorial controller
      initialState: 'noTutorial'

      # no tutorial. (Can't be empty, so has an 'empty' methof)
      noTutorial: Ember.State.create
        empty: ->

      # tutorial state
      waitingForTraitSelection: Ember.State.create
        selectTrait: (manager, characteristic) ->
          if characteristic is "wings"
            manager.transitionTo 'waitingForParentSelection'

        parentSelected: ->
          # do nothing
        goToTown: (manager) ->
          # no nothing
        goToWorld: (manager) ->
          # no nothing

      # tutorial state
      waitingForParentSelection: Ember.State.create
        setup: ->
          # show parent tutorial after first selected
          GG.tutorialMessageController.showMaleParentsTutorial()

        parentSelected: (manager, parent) ->
          sex = parent.get('sex')
          if sex is GG.MALE
            @get('parentState').parentSelected(manager, parent)
            GG.tutorialMessageController.showFemaleParentsTutorial()
          else if GG.breedingController.get('father')
            @get('parentState').parentSelected(manager, parent)
            manager.transitionTo 'noTutorial'

        goToTown: (manager) ->
          # no nothing
        goToWorld: (manager) ->
          # no nothing


    animatingMeiosis: Ember.State.create
      firstTime: true
      setup: (manager)->
        @set('firstTime', true)
        GG.meiosisController.selectFirstParent(null)
        $("#breeder").animate({left: -459},500,"easeOutCubic")
        # hide the offspring pool
        $("#offspring-panel").animate({left: 400},500,"easeOutCubic")
        $("#offspring-pool .chromosome-panel").hide()
        $("#chromosome-labels-offspring").hide()
        setTimeout ->
          GG.tutorialMessageController.showMeiosisSelectionTutorial()
        , 1000
        scale = GG.MeiosisAnimation.get 'timeScale'
        setTimeout ->
          $('#chromosome-labels').hide()
          GG.motherPoolController.set('hidden', true)
          GG.fatherPoolController.set('hidden', true)
        , GG.MeiosisAnimation.scale(600)
        setTimeout ->
          manager.send 'animate'
        , GG.MeiosisAnimation.scale(800)

      selectMotherMeiosis: ->
        GG.meiosisController.selectFirstParent("mother")
      selectFatherMeiosis: ->
        GG.meiosisController.selectFirstParent("father")

      animate: (manager)->
        $(".parent-select-target").addClass("active")
        scale = GG.MeiosisAnimation.get 'timeScale'
        firstTime = @get 'firstTime'
        @set('firstTime', false)
        delay = if firstTime then GG.MeiosisAnimation.scale(2000) else 1

        if GG.cyclesController.get('cycles') <= 0
          GG.reputationController.subtractReputation(GG.actionCostsController.getCost('extraBreedCycle'), GG.Events.BRED_WITH_EXTRA_CYCLE)
        manager.send 'decrementCycles', 1
        GG.breedingController.set 'childSavedToParents', false
        $('#meiosis-container').removeClass('hidden')
        $("#offspring-pool .chromosome-panel").hide()
        $("#chromosome-labels-offspring").hide()
        $('#chromosome-labels-meiosis').fadeIn(GG.MeiosisAnimation.scale(200))
        setTimeout ->
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

      goToTown: (manager) ->
        GG.meiosisController.resetAnimation()
        manager.transitionTo 'inTown'

      goToWorld: (manager) ->
        GG.meiosisController.resetAnimation()
        manager.transitionTo 'inWorld'

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
        $("#offspring-pool .chromosome-panel").show()
        $("#chromosome-labels-offspring").show()
        $('#offspring-panel').animate({left: -76},300,"easeOutCubic")
        setTimeout ->
          GG.tutorialMessageController.showFinishButtonTutorial()
          GG.tutorialMessageController.showBackcrossButtonTutorial()
        , 1200

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
        GG.hideInfoDialogs()
        manager.send 'hideLeaderboard'
        GG.obstacleCourseController.set('dialogVisible', false)
        $('#obstacle-course-dialog').hide()
        $('#modal-backdrop-fade').hide()
