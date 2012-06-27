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

GG.ChromoView = Ember.View.extend
  templateName: 'chromosome'
  content: null
  chromo: '1'
  side: 'a'
  genes: (->
    GG.genetics.chromosomeGeneMap[@get 'chromo']
  ).property('chromo')
  alleles: (->
    res = []
    src = 'chromoView' + @get('chromo') + @get('side') + ".alleles"
    if (@get 'content')?
      fullGeno = @getPath 'content.visibleGenotype'
      geno = fullGeno[@get 'side']
      res = GG.genetics.filter(geno, @get 'genes')
    return res
  ).property('chromo','content','side')
  defaultClass: 'chromosome'
  chromoName: (->
    'chromo-'+@get('chromo')
  ).property('chromo','side')
  right: (->
    @get('chromo') == 'Y' or @get('side') == 'b'
  ).property('chromo','side')
  classNameBindings: ['defaultClass', 'chromoName', 'right']

GG.ChromosomePanelView = Ember.View.extend
  templateName: 'chromosome-panel'
  hiddenBinding: '*controller.hidden'
  defaultClass: 'chromosome-panel'
  classNameBindings: ['hidden','defaultClass']
