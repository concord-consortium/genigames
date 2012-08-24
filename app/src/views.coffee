minispade.require 'genigames/view-mixins'
minispade.require 'genigames/meiosis-animation'

GG.WorldView = Ember.View.extend
  templateName: 'world'
  contentBinding: 'GG.townsController'

GG.WorldTownView = Ember.View.extend
  classNameBindings: ['icon','location']
  attributeBindings: ['style']
  location: "location"
  icon: (->
    @getPath('content.icon')
  ).property('content.icon')
  style: (->
    # TODO how do we do width and height?
    width = 120
    height = 120
    # calculate the position of the town based on the position
    # with the center at a,b, r = radius, t = angle:
    # (a + r cos t, b + r sin t)
    # add 90 since the equation assumes 0 is on the right of the circle, not top
    # subtract because the coordinate
    posRadX = (@getPath('content.position') + 90) * (Math.PI/180)
    # subtract for Y since the coordinate system is mirrored on the Y-axis
    posRadY = (@getPath('content.position') - 90) * (Math.PI/180)
    x = Math.round(350 + (250 * Math.cos(posRadX)) - (width/2))
    y = Math.round(350 + (250 * Math.sin(posRadY)) - (height/2))
    return "left: " + x + "px; top: " + y + "px; " + @get('rotation')
  ).property('content.position')
  rotation: (->
    rot = "rotate(-" + @getPath('content.position') + "deg); "
    return "transform: " + rot +
      "-ms-transform: " + rot +
      "-webkit-transform: " + rot +
      "-o-transform: " + rot +
      "-moz-transform: " + rot
  ).property('content.position')
  click: ->
    GG.statemanager.send 'townSelected', @get('content')


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

  drakeRemoved: (evt) ->
    drake = evt.context
    GG.statemanager.send 'parentRemoved', drake

GG.FatherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.fatherPoolController'
  expanderButton: Ember.View.extend
    classNames: ['expander']
    click: ->
      GG.statemanager.send 'toggleFatherPool'
  meiosisButton: Ember.View.extend
    classNames: ['meiosis-button']
    click: ->
      GG.statemanager.send 'startFatherMeiosis'

GG.MotherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.motherPoolController'
  expanderButton: Ember.View.extend
    classNames: ['expander']
    click: ->
      GG.statemanager.send 'toggleMotherPool'
  meiosisButton: Ember.View.extend
    classNames: ['meiosis-button']
    click: ->
      GG.statemanager.send 'startMotherMeiosis'

GG.OffspringPoolView = Ember.View.extend
  drakeSelected: (evt) ->
    drake = evt.context
    GG.statemanager.send 'offspringSelected', drake

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
  parent: (->
    if @get('side') == 'a' then 'mother' else 'father'
  ).property('chromo','side')
  classNameBindings: ['defaultClass', 'chromoName', 'right', 'parent']

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

GG.MatchGoalCounter = Ember.View.extend
  templateName: 'match-goal-counter'
  targetCountBinding: Ember.Binding.oneWay('GG.tasksController.targetCount')
  classNameBindings: ['hidden','defaultClass']
  defaultClass: 'match-goal-counter'
  hidden: (->
    @get('targetCount') <= 1
  ).property('targetCount')

GG.TownView = Ember.View.extend
  templateName: 'town'
  contentBinding: 'GG.tasksController'

GG.TaskNPCView = Ember.View.extend
  tagName            : 'div'
  classNameBindings  : ['npc', 'npcId']
  npc                : 'npc'
  npcId              : (->
    imageURL = @getPath 'content.npc.imageURL'
    /([^\.\/]+)[\.]/.exec(imageURL)[1]
  ).property('src')
  npcSelected: (evt) ->
    GG.statemanager.send 'npcSelected', evt.context

GG.NPCView = Ember.View.extend
  tagName            : 'img'
  classNames         : ['character']
  attributeBindings  : ['src']
  srcBinding         : 'content.npc.imageURL'

GG.NPCQuestionBubbleView = Ember.View.extend GG.Animation,
  tagName            : 'img'
  classNames         : ['bubble']
  classNameBindings  : ['hidden']
  attributeBindings  : ['src']
  src                : '../images/bubble-question.png'
  hiddenBinding      : Ember.Binding.oneWay('content.showQuestionBubble').not()
  onShow: ->
    @animateSequence
      sequence:
        [properties: {top: "-=20px"}, duration: 200, easing: 'easeOutCubic',
         properties: {top: "+=20px"}, duration: 200, easing: 'easeInCubic']
      delay: 200
      repeat: 2

GG.NPCSpeechBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : (->
    return new Handlebars.SafeString(@getPath 'content.npc.speech.text')
  ).property('content')
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hiddenBinding      : Ember.Binding.oneWay('content.showSpeechBubble').not()
  accept: ->
    GG.statemanager.send 'accept', @get 'content'
  decline: ->
    GG.statemanager.send 'decline'

GG.NPCCompletionBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : (->
    return new Handlebars.SafeString(@getPath 'content.npc.speech.completionText')
  ).property('content')
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hiddenBinding      : Ember.Binding.oneWay('content.showCompletionBubble').not()
  accept: ->
    GG.tasksController.taskCompleted(@get 'content')
