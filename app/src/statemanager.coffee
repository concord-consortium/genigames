###
STATES:

  inTask
    showingBreeder
###

GG.statemanager = Ember.StateManager.create
  initialState: 'inTask'

  inTask: Ember.State.create
    initialState: 'showingBreeder'

    showingBreeder: Ember.State.create
      enter: ->
        # animate machine coming down and wings opening

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
          motherContainer.animate({width: 108},{duration: 1000})
          motherPool.animate({left: -5},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -0px')
          })
        else
          motherContainer.animate({width: 277},{duration: 1000})
          motherPool.animate({left: 165},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -15px')
          })

        @set 'mothersExpanded', !@get 'mothersExpanded'

      fathersExpanded: false
      toggleFatherPool: ->
        fatherContainer = $('#parent-fathers-pool-container')
        fatherPool = $('#parent-fathers-pool-container .parent-pool')
        fatherExpander = $('#parent-fathers-pool-container .expander')
        if @get 'fathersExpanded'
          fatherContainer.animate({width: 108, left: 159},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -15px')
          })
        else
          fatherContainer.animate({width: 280, left: -9},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -0px')
          })

        @set 'fathersExpanded', !@get 'fathersExpanded'


