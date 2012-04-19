minispade.require 'genigames/vendor/jquery-1.6.1.min'
minispade.require 'genigames/vendor/ember-0.9.5'

window.GG = GG = Ember.Application.create()

minispade.require 'genigames/gen-gwt'
minispade.require 'genigames/genetics'

GG.Task = Ember.Object.extend
  visibleAlleles: null

GG.tasksController = Ember.ArrayController.create
  content: []
  currentTask: null

GG.Drake = Ember.Object.extend
  gOrg: null            # organism object created by GWT
  sex: null
  imageURL: null
  genotype: (->
    alleleString = @getPath "gOrg.alleles"
    aArray = alleleString.match(/a:([^,])*/g).map (short) ->
      short.match(/[^:]+$/)[0]
    bArray = alleleString.match(/b:([^,])*/g).map (short) ->
      short.match(/[^:]+$/)[0]
    return {a: aArray, b: bArray}
  ).property('gOrg').cacheable()
  visibleGenotype: (->
    visibleAlleles = GG.tasksController.getPath "currentTask.visibleAlleles"
    return GG.genetics.filterGenotype(@get("genotype"), visibleAlleles)
  ).property("genotype", "GG.tasksController.currentTask").cacheable()

GG.parentController = Ember.ArrayProxy.create
  content: []
  females: (->
    drake for drake in @get('content') when drake.sex is 1
  ).property('content.@each').cacheable()
  males: (->
    drake for drake in @get('content') when drake.sex is 0
  ).property('content.@each').cacheable()
  selectedMother: null
  selectedFather: null

GG.offspringController = Ember.ArrayProxy.create
  content: []

GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  child: null
  breedDrake: ->
    if @get('mother') && @get('father')
      GenGWT.breedDragon this.get('mother').gOrg, this.get('father').gOrg, (gOrg) ->
        drake = GG.Drake.create
          imageURL: gOrg.imageURL
          sex: gOrg.sex
          gOrg: gOrg
        GG.breedingController.set 'child', drake
        GG.offspringController.pushObject drake

GG.DrakeView = Ember.View.extend
  tagName: 'img'
  attributeBindings: ['src', 'width']
  srcBinding: 'content.imageURL'
  width: 200
  clickToBecomeParent: false
  click: (evt) ->
    drake = @get('content')
    if (@clickToBecomeParent)
      whichParent = if drake.get('sex') is 0 then 'selectedMother' else 'selectedFather'
      GG.parentController.set whichParent, drake

GG.AllelesView = Ember.View.extend
  tagName: 'span'
  allelesString: (->
    genotype = @getPath 'content.visibleGenotype'
    genotype.a.concat(genotype.b).join(",")
  ).property('content').cacheable()

# on load
$ ->
  # create sample task
  task = GG.Task.create
    visibleAlleles: ["T"]

  GG.tasksController.pushObject(task);
  GG.tasksController.set "currentTask", task

  # create initial parents, after waiting half a second for GWT to load
  setTimeout ->
    for i in [0..5]
      GenGWT.generateAliveDragonWithSex i%2, (gOrg) =>
        drake = GG.Drake.create
          imageURL: gOrg.imageURL
          sex: gOrg.sex
          gOrg: gOrg
        GG.parentController.pushObject(drake)

  , 2000
