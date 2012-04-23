GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null

  addTask: (task) ->
    @get('content').pushObject task

  setCurrentTask: (task) ->
    if @get('content').indexOf(task) >= 0
      @set 'currentTask', task
    else
      throw "GG.tasksController.setCurrentTask: argument is not a known task"


GG.parentController = Ember.ArrayProxy.create
  content: []
  selectedMother: null
  selectedFather: null

  females: (->
    drake for drake in @get('content') when drake.sex is GG.FEMALE
  ).property('content.@each').cacheable()

  males: (->
    drake for drake in @get('content') when drake.sex is GG.MALE
  ).property('content.@each').cacheable()

  selectMother: (drake) ->
    if drake.sex isnt GG.FEMALE then throw "GG.parentController.selectMother: tried to set a non-female as mother"
    @set 'selectedMother', drake

  selectFather: (drake) ->
    if drake.sex isnt GG.MALE then throw "GG.parentController.selectMother: tried to set a non-male as father"
    @set 'selectedFather', drake


GG.fatherPoolController = Ember.ArrayProxy.create
  contentBinding: 'GG.parentController.males'
  drakeSelected: (drake) ->
    GG.parentController.selectFather drake

GG.motherPoolController = Ember.ArrayProxy.create
  contentBinding: 'GG.parentController.females'
  drakeSelected: (drake) ->
    GG.parentController.selectMother drake


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