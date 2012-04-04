window.GG = GG = Ember.Application.create()

GG.Task = Ember.Object.extend
  visibleAlleles: null

GG.Drake = Ember.Object.extend
  gOrg: null            # organism object created by GWT
  sex: null
  alleles: null
  imageURL: null

GG.parentController = Ember.ArrayProxy.create
  content: []
  females: (->
    females = (drake for drake in @get("content") when drake.sex == 1)
  ).property("content.@each").cacheable()
  males: (->
    males = (drake for drake in @get("content") when drake.sex == 0)
  ).property("content.@each").cacheable()
  selectedMother: null
  selectedFather: null

GG.offspringController = Ember.ArrayProxy.create
  content: []

GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  child: null
  breedDrake: ->
    if this.get('mother') && this.get('father')
      GenGWT.breedDragon this.get('mother').gOrg, this.get('father').gOrg, (gOrg) ->
        drake = GG.Drake.create
          imageURL: gOrg.imageURL
          sex: gOrg.sex
          gOrg: gOrg
        GG.breedingController.set('child', drake)
        GG.offspringController.pushObject(drake)

GG.DrakeView = Ember.View.extend
  tagName: 'img'
  attributeBindings: ['src', 'width']
  srcBinding: 'content.imageURL'
  width: 200
  clickToBecomeParent: false
  click: (evt) ->
    drake = this.get('content')
    if (this.clickToBecomeParent)
      whichParent = if (drake.get('sex') == 0) then 'selectedMother' else 'selectedFather'
      GG.parentController.set(whichParent, drake)

# on load
$ ->
  # create initial parents, after waiting half a second for GWT to load
  setTimeout ->
    for i in [0..5]
      GenGWT.generateAliveDragonWithSex i%2, (gOrg) =>
        drake = GG.Drake.create
          imageURL: gOrg.imageURL
          sex: gOrg.sex
          gOrg: gOrg
        GG.parentController.pushObject(drake)
          
  , 3000
