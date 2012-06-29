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

GG.AlleleView = Ember.View.extend
  classNames: ['allele']
  value: ''
  hidden: false
  displayValue: (->
    if @get('hidden') then '?' else @get('value')
  ).property('value','hidden')
  click: ->
    if @get('hidden')
      GG.statemanager.send 'incrementCounter'
      @set 'hidden', false
      if (@get 'drake')? and (@get 'side')?
        @get('drake').markRevealed(@get('side'), @get('value'))

GG.ChromoView = Ember.View.extend
  templateName: 'chromosome'
  content: null
  chromo: '1'
  side: 'a'
  genes: (->
    GG.genetics.chromosomeGeneMap[@get 'chromo']
  ).property('chromo')
  visibleAlleles: (->
    res = []
    if (@get 'content')?
      fullGeno = @getPath 'content.visibleGenotype'
      geno = fullGeno[@get 'side']
      res = GG.genetics.filter(geno, @get 'genes')
    return res
  ).property('chromo','content','side')
  hiddenAlleles: (->
    res = []
    if (@get 'content')?
      fullGeno = @getPath 'content.hiddenGenotype'
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

GG.EggView = Ember.View.extend
  tagName: 'div'
  hiddenBinding: Ember.Binding.oneWay('GG.breedingController.isBreeding').not()
  classNameBindings: ['hidden']
  animationObserver: (->
    @startAnimation() if (!@get 'hidden')
  ).observes('hidden')
  startAnimation: ->
    $('#egg').css({backgroundPosition: '0px 0px'})
    $('#egg').animate({rotate: '0deg'}, 0)
    setTimeout ->
      $('#egg').animate({rotate: '+=20deg'}, 50)
        .animate({rotate: '-=20deg'}, 50)
        .animate({rotate: '+=20deg'}, 50)
        .animate({rotate: '-=20deg'}, 50)
        .animate({rotate: '+=20deg'}, 50)
        .animate {rotate: '-=60deg'}, 50, ->
          $('#egg').animate({rotate: '+=60deg',0}, 0)
            .css({backgroundPosition: '0px -140px'})
    , 700

GG.MoveCounter = Ember.View.extend
  templateName: 'move-counter'
  classNames: ['move-counter']
