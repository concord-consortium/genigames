minispade.require 'genigames/view-mixins'

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
  classNameBindings: ['defaultClassNames', 'hidden:revealable']
  defaultClassNames: 'allele'
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
  hiddenBinding: 'controller.hidden'
  defaultClass: 'chromosome-panel'
  classNameBindings: ['hidden','defaultClass']

GG.EggView = Ember.View.extend GG.Animation,
  tagName: 'div'
  hiddenBinding: Ember.Binding.oneWay('GG.breedingController.isBreeding').not()
  classNameBindings: ['hidden']
  onShow: ->
    @$().css({backgroundPosition: '0px 0px'})
    @animate(properties: {rotate: '0deg'}, delay: 0)
    @animateSequence
      sequence:
        [properties: {rotate: '+=20deg'}, duration: 50,
         properties: {rotate: '-=20deg'}, duration: 50]
      delay: 700
      repeat: 3
      callback: =>
        @$().css({backgroundPosition: '0px -140px'})

GG.MoveCounter = Ember.View.extend
  templateName: 'move-counter'
  classNames: ['move-counter']

GG.TownView = Ember.View.extend
  templateName: 'town'
  contentBinding: 'GG.tasksController'

  npcSelected: (evt) ->
    GG.statemanager.send 'npcSelected', evt.context

GG.TaskNPCView = Ember.View.extend
  tagName            : 'div'
  classNameBindings  : ['npc', 'npcId']
  npc                : 'npc'
  npcId              : (->
    imageURL = @getPath 'content.npc.imageURL'
    /([^\.\/]+)[\.]/.exec(imageURL)[1]
  ).property('src')

GG.NPCView = Ember.View.extend
  tagName            : 'img'
  classNames         : ['character']
  attributeBindings  : ['src']
  srcBinding         : 'content.npc.imageURL'

GG.NPCBubbleQuestionView = Ember.View.extend GG.Animation,
  tagName            : 'img'
  classNames         : ['bubble']
  classNameBindings  : ['hidden']
  attributeBindings  : ['src']
  src                : '../images/bubble-question.png'
  hiddenBinding      : Ember.Binding.oneWay('content.showBubble').not()
  onShow: ->
    @animateSequence
      sequence:
        [properties: {top: "-=20px"}, duration: 200, easing: 'easeOutCubic',
         properties: {top: "+=20px"}, duration: 200, easing: 'easeInCubic']
      delay: 200
      repeat: 2
