GG.BreederView = Ember.View.extend
  templateName: 'breeder-view'


GG.DrakeView = Ember.View.extend
  tagName            : 'img'
  attributeBindings  : ['src', 'width']
  srcBinding         : 'content.imageURL'
  width              : 200


GG.ParentPoolView = Ember.View.extend
  templateName: 'parent-pool-view'
  contentBinding: 'controller.content'

  drakeSelected: (evt) ->
    drake = evt.context
    GG.statemanager.send 'parentSelected', drake

GG.FatherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.fatherPoolController'
  expanderButton: Ember.View.extend
    classNames: ['expander']
    click: ->
      GG.statemanager.send 'toggleFatherPool'

GG.MotherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.motherPoolController'
  expanderButton: Ember.View.extend
    classNames: ['expander']
    click: ->
      GG.statemanager.send 'toggleMotherPool'


GG.AllelesView = Ember.View.extend
  tagName: 'span'

  allelesString: (->
    genotype = @getPath 'content.visibleGenotype'
    genotype.a.concat(genotype.b).join(',') unless !genotype
  ).property('content.visibleGenotype').cacheable()

GG.BreedButtonView = Ember.View.extend
  tagName: 'div'

  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'

  classNameBindings : ['enabled']
  enabled: (->
    !!(this.get('mother') && this.get('father'))
  ).property('mother', 'father')

  click: ->
    GG.statemanager.send('breedDrake')
