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
          motherContainer.animate({left: 595},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -0px')
            $('#parent-mothers-pool-container .chromosome-panel').hide()
          })
        else
          motherContainer.animate({left: 721},{duration: 1000, complete: ->
            motherExpander.css('backgroundPosition','-0px -15px')
            $('#parent-mothers-pool-container .chromosome-panel').show()
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
            $('#parent-fathers-pool-container .chromosome-panel').hide()
          })
        else
          fatherContainer.animate({left: 1},{duration: 1000, complete: ->
            fatherExpander.css('backgroundPosition','-0px -0px')
            $('#parent-fathers-pool-container .chromosome-panel').show()
          })

        @set 'fathersExpanded', !@get 'fathersExpanded'


