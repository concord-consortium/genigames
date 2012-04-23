GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null

  addTask: (task) ->
    @get('content').pushObject task

  setCurrentTask: (task) ->
    if @get('content').indexOf(task) >= 0
      @set 'currentTask', task
    else
      throw "tasksController.setCurrentTask: argument is not a known task"


GG.parentController = Ember.ArrayProxy.create
  content       : []
  selectedMother: null
  selectedFather: null

  selectParent: (drake) ->
    whichParent = if drake.get('sex') is 0 then 'selectedMother' else 'selectedFather'
    @set whichParent, drake

  females: (->
    drake for drake in @get('content') when drake.sex is 1
  ).property('content.@each').cacheable()

  males: (->
    drake for drake in @get('content') when drake.sex is 0
  ).property('content.@each').cacheable()


GG.offspringController = Ember.ArrayProxy.create
  content: []


GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  child: null

  breedDrake: ->
    if @get('mother') && @get('father')
      GenGWT.breedDragon @getPath('mother.biologicaOrganism'), @getPath('mother.biologicaOrganism'), (org) ->
        drake = GG.Drake.createFromBiologicaOrganism org
        GG.breedingController.set 'child', drake
        GG.offspringController.pushObject drake