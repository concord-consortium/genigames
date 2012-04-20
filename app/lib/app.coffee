minispade.require 'genigames/vendor/jquery'
minispade.require 'genigames/vendor/ember'

window.GG = GG = Ember.Application.create()

minispade.require 'genigames/gen-gwt'
minispade.require 'genigames/genetics'
minispade.require 'genigames/templates/main-view'


GG.Task = Ember.Object.extend
  visibleGenes: null


GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null


GG.Drake = Ember.Object.extend
  biologicaOrganism : null            # organism object created by GWT
  sex               : null
  imageURL          : null

  genotype: (->
    alleleString = @getPath 'biologicaOrganism.alleles'

    a: alleleString.match(/a:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
    b: alleleString.match(/b:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
  ).property('biologicaOrganism').cacheable()

  visibleGenotype: (->
    visibleGenes = GG.tasksController.getPath 'currentTask.visibleGenes'

    GG.genetics.filterGenotype @get('genotype'), visibleGenes
  ).property('genotype', 'GG.tasksController.currentTask').cacheable()


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
        drake = GG.Drake.create
          biologicaOrganism: org
          imageURL         : org.imageURL
          sex              : org.sex

        GG.breedingController.set 'child', drake
        GG.offspringController.pushObject drake


GG.MainView = Ember.View.extend
  templateName: 'main-view'


GG.DrakeView = Ember.View.extend
  tagName            : 'img'
  attributeBindings  : ['src', 'width']
  srcBinding         : 'content.imageURL'
  width              : 200
  clickToBecomeParent: false

  click: (evt) ->
    drake = @get('content')
    if @clickToBecomeParent
      whichParent = if drake.get('sex') is 0 then 'selectedMother' else 'selectedFather'
      GG.parentController.set whichParent, drake


GG.AllelesView = Ember.View.extend
  tagName: 'span'
  allelesString: (->
    genotype = @getPath 'content.visibleGenotype'

    genotype.a.concat(genotype.b).join(',')
  ).property('content').cacheable()


# on load
$ ->
  # create sample task
  task = GG.Task.create
    visibleGenes: ['T']

  GG.tasksController.pushObject task
  GG.tasksController.set 'currentTask', task

  # create initial parents, after waiting half a second for GWT to load
  setTimeout ->
    for i in [0..5]
      GenGWT.generateAliveDragonWithSex i%2, (org) ->
        GG.parentController.pushObject GG.Drake.create
          biologicaOrganism: org
          imageURL         : org.imageURL
          sex              : org.sex
  , 2000
