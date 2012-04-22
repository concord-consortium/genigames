GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null


GG.parentController = Ember.ArrayProxy.create
  content       : []
  selectedMother: null
  selectedFather: null

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