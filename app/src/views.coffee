minispade.require 'genigames/view-mixins'
minispade.require 'genigames/meiosis-animation'

GG.LoginView = Ember.View.extend
  templateName: 'login'
  username: ""
  password: ""
  loggingInBinding: 'GG.sessionController.loggingIn'
  errorBinding: 'GG.sessionController.error'
  firstTimeBinding: 'GG.sessionController.firstTime'
  login: ->
    pw = @get('password')
    @set('password', "")
    @set('loggingIn', true)
    data = {username: @get('username'), password: pw}
    GG.statemanager.send 'login', data

GG.ChooseClassView = Ember.View.extend
  templateName: 'choose-class'
  optionsBinding: 'GG.sessionController.classesWithLearners'
  learner: null
  choose: ->
    GG.statemanager.send 'chooseLearner', @get('learner')

GG.WorldView = Ember.View.extend
  templateName: 'world'
  contentBinding: 'GG.townsController'

GG.WorldTownView = Ember.View.extend
  classNameBindings: ['icon','location']
  attributeBindings: ['style']
  location: "location"
  icon: (->
    @get('content.icon')
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
    posRadX = (@get('content.position') + 90) * (Math.PI/180)
    # subtract for Y since the coordinate system is mirrored on the Y-axis
    posRadY = (@get('content.position') - 90) * (Math.PI/180)
    x = Math.round(350 + (250 * Math.cos(posRadX)) - (width/2))
    y = Math.round(350 + (250 * Math.sin(posRadY)) - (height/2))
    return "left: " + x + "px; top: " + y + "px; " + @get('rotation')
  ).property('content.position')
  rotation: (->
    rot = "rotate(-" + @get('content.position') + "deg); "
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
  templateName       : 'drake'
  drakeImage         : (->
    color = @get('org').getCharacteristic 'color'
    if color is "Gray"
      '../images/drakes/gray-static.png'
    else '../images/drakes/green-static.png'
  ).property()
  width              : "200px"
  org : (->
    @get('content.biologicaOrganism')
  ).property().cacheable()
  tail : (->
    tail = @get('org').getCharacteristic "tail"
    if tail is "Long tail"
      'drake-long-tail'
    else if tail is "Kinked tail"
      'drake-kinked-tail'
    else 'drake-short-tail'
  ).property()
  forelimbs : (->
    forelimbs = @get('org').getCharacteristic "forelimbs"
    if forelimbs is "Long forelimbs"
      'drake-long-forelimbs'
    else 'drake-short-forelimbs'
  ).property()
  wings : (->
    wings = @get('org').getCharacteristic "wings"
    if wings is "Wings"
      'drake-wings'
    else 'trait-absent'
  ).property()
  spikes : (->
    spikes = @get('org').getCharacteristic "spikes"
    if spikes is "Wide spikes"
      'drake-wide-spikes'
    else if spikes is "Medium spikes"
      'drake-medium-spikes'
    else 'drake-thin-spikes'
  ).property()
  head : (->
    sex = if @get('content.sex') is GG.FEMALE then "female" else "male"
    'drake-'+sex
  ).property()
  horns : (->
    horns = @get('org').getCharacteristic "horns"
    if horns is "Horns"
      'drake-horns'
    else 'trait-absent'
  ).property()
  fire : (->
    fire = @get('org').getCharacteristic "fire breathing"
    if fire is "Fire breathing"
      'drake-fire'
    else 'trait-absent'
  ).property()

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

GG.MotherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.motherPoolController'

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
  hiddenValue: (->
    value = @get 'value'
    if value is "Tk" then value = "T"
    if value is "A1" or value is "A2" then value = "A"
    value = value.charAt(0).toUpperCase() + value.slice(1);
    value + '?'
  ).property('value').cacheable()
  hidden: false
  displayValue: (->
    if @get('hidden') then @get('hiddenValue') else @get('value')
  ).property('value','hidden')
  click: ->
    if @get('hidden')
      GG.userController.addReputation -GG.actionCostsController.getCost 'alleleRevealed'
      @set 'hidden', false
      if (@get 'drake')? and (@get 'side')?
        @get('drake').markRevealed(@get('side'), @get('value'))
      GG.logController.logEvent GG.Events.REVEALED_ALLELE, allele: @get('value'), side: @get('side'), drake: { alleles: @get('drake.biologicaOrganism.alleles'), sex: @get('drake.sex') }

GG.ChromoView = Ember.View.extend
  templateName: 'chromosome'
  content: null
  chromo: '1'
  side: 'a'
  sister: null
  gametes: null
  gamete: (->
    if @get('gametes')?
      cell = (if @get('side') == 'a' then 0 else 1) + (if @get('sister') == "1" then 0 else 2)
      chromo = @get('chromo')
      chromo = if chromo == "X" or chromo == "Y" then "XY" else chromo
      return @get('gametes').cells[cell][chromo].alleles
    else
      return null
  ).property('chromo','side','sister','gametes')
  visibleGamete: (->
    res = null
    if @get('gamete')?
      res = GG.Genetics.filter(@get('gamete'), GG.drakeController.get('visibleGenes'))
    return res
  ).property('gamete')
  hiddenGamete: (->
    res = null
    if @get('gamete')?
      res = GG.Genetics.filter(@get('gamete'), GG.drakeController.get('hiddenGenes'))
    return res
  ).property('gamete')
  biologicaChromoName: (->
    chromo = @get 'chromo'
    return chromo unless chromo is "X" or chromo is "Y"
    return "XY"
  ).property('chromo')
  genes: (->
    GG.Genetics.species.chromosomeGeneMap[@get 'biologicaChromoName']
  ).property('chromo')
  visibleAlleles: (->
    res = []
    if (@get 'content')? or (@get 'visibleGamete')?
      geno = null
      if (@get 'visibleGamete')?
        geno = @get 'visibleGamete'
      else
        fullGeno = @get 'content.visibleGenotype'
        geno = fullGeno[@get 'side']
      res = GG.Genetics.filter(geno, @get 'genes')
    return res
  ).property('chromo','content','side','visibleGamete')
  hiddenAlleles: (->
    res = []
    if (@get 'content')? or (@get 'hiddenGamete')?
      geno = null
      if (@get 'hiddenGamete')
        geno = @get 'hiddenGamete'
      else
        fullGeno = @get 'content.hiddenGenotype'
        geno = fullGeno[@get 'side']
      res = GG.Genetics.filter(geno, @get 'genes')
    return res
  ).property('chromo','content','side','hiddenGamete')
  defaultClass: 'chromosome'
  chromoName: (->
    'chromo-'+@get('chromo')
  ).property('chromo','side')
  right: (->
    if @get('chromo') == 'Y' or @get('side') == 'b' then "right" else "left"
  ).property('chromo','side')
  parent: (->
    if @get('side') == 'a' then 'mother' else 'father'
  ).property('chromo','side')
  sisterClass: (->
    if (@get 'sister')?
      return "sister-" + @get('sister')
    else
      return ""
  ).property('sister')
  hidden: false
  classNames: ['chromosome']
  classNameBindings: ['chromoName', 'right', 'parent', 'sisterClass', 'hidden']

GG.ChromosomePanelView = Ember.View.extend
  templateName: 'chromosome-panel'
  hiddenBinding: 'controller.hidden'
  defaultClass: 'chromosome-panel'
  chromosomeClass: (->
    if @get('controller.selected.sex') is GG.FEMALE then 'female-chromosome'
    else 'male-chromosome'
  ).property('controller.selected').cacheable()
  classNameBindings: ['hidden','defaultClass', 'chromosomeClass']

GG.EggView = Ember.View.extend GG.Animation,
  tagName: 'div'
  hidden: Ember.computed.not('GG.breedingController.isBreeding')
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

GG.OffspringUseButtonView = Ember.View.extend
  tagName: 'div'
  classNames : 'offspring-buttons-use'
  click: ->
    GG.statemanager.send('submitOffspring')

GG.OffspringSaveButtonView = Ember.View.extend
  tagName: 'div'
  classNames : 'offspring-buttons-save'
  click: ->
    GG.statemanager.send('saveOffspring')

GG.OffspringFreeButtonView = Ember.View.extend
  tagName: 'div'
  classNames : 'offspring-buttons-free'
  click: ->
    GG.statemanager.send('freeOffspring')

GG.BreedTitleView = Ember.View.extend
  tagName: 'div'
  classNames: 'breed-title'
  text: (->
    # not sure if it's ok the query the statemanager like this....
    if GG.statemanager.get('currentState.name') is "parentSelect"
      "Parent selection"
    else "Breeding"
  ).property('GG.statemanager.currentState')

GG.TaskDescriptionView = Ember.View.extend
  tagName: 'div'
  classNames: 'task-description'
  currentTaskBinding: 'GG.tasksController.currentTask'
  text: (->
    authoredText = @get 'currentTask.npc.speech.text'
    text = ""
    if authoredText
      # FIXME This results in some pretty ugly text...
      text = authoredText.reduce((prev, item, idx, arr)->
        return prev + " " + item
      )
      text = text.replace(/(<([^>]+)>)/ig, " ")
    return text
  ).property('currentTask').cacheable()

GG.SelectParentsButtonView = Ember.View.extend
  tagName: 'div'
  classNames : 'select-parents'
  click: ->
    GG.statemanager.send('selectParents')

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
  classNames         : 'npc'
  attributeBindings  : ['style']
  style: (->
    "top: " + @get('content.npc.position.y') + "px; left: " + @get('content.npc.position.x') + "px;"
  ).property('content.npc.position.x','content.npc.position.y')
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
  hidden             : Ember.computed.not('content.showQuestionBubble')
  onShow: ->
    @animateSequence
      sequence:
        [properties: {top: "-=20px"}, duration: 200, easing: 'easeOutCubic',
         properties: {top: "+=20px"}, duration: 200, easing: 'easeInCubic']
      delay: 200
      repeat: 2

GG.NPCSpeechBubbleView = Ember.View.extend
  tagName            : 'div'
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showSpeechBubble')
  textIdx            : 0
  lastTextIdx        : 0
  init               : ->
    @_super()
    @resetTextIdx()
  text               : (->
    authoredText = @get 'content.npc.speech.text'
    return new Handlebars.SafeString(authoredText[@get 'textIdx'])
  ).property('content','textIdx')
  isLastText: (->
    return @get('textIdx') >= @get('lastTextIdx')
  ).property('textIdx','lastTextIdx')
  resetTextIdx: (->
    @set 'textIdx', 0
    authoredText = @get 'content.npc.speech.text'
    @set 'lastTextIdx', (authoredText.length - 1)
  ).observes('content')
  next: ->
    @set('textIdx', @get('textIdx') + 1)
  accept: ->
    GG.statemanager.send 'accept', @get 'content'
  decline: ->
    @resetTextIdx()
    GG.statemanager.send 'decline'

GG.NPCCompletionBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : (->
    return new Handlebars.SafeString(@get 'content.npc.speech.completionText')
  ).property('content')
  classNames         : ['speech-bubble-no-npc']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showCompletionBubble')
  accept: ->
    GG.tasksController.taskFinishedBubbleDismissed()

GG.NPCNonCompletionBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : "That's not the drake you're looking for!"
  classNames         : ['speech-bubble-no-npc']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showNonCompletionBubble')
  accept: ->
    GG.tasksController.nonCompletionBubbleDismissed()

GG.NPCHeartBubbleView = Ember.View.extend
  tagName            : 'img'
  classNames         : ['heart-bubble']
  classNameBindings  : ['hidden']
  attributeBindings  : ['src']
  src                : '../images/heart-bubble.png'
  hidden             : Ember.computed.not('content.completed')

GG.NPCFinalMessageBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : (->
    return new Handlebars.SafeString(GG.townsController.get("currentTown.finalMessage"))
  ).property('content')
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showFinalMessageBubble')
  next: ->
    GG.statemanager.transitionTo 'inWorld.movingDirectlyToNextTown'
  world: ->
    GG.statemanager.transitionTo 'inWorld.townsWaiting'

GG.MeiosisView = Ember.View.extend
  templateName: 'meiosis'
  tagName: 'div'
  content: null
  classNames: ['meiosis']
  classNameBindings: ['motherFather']
  motherFather: (->
    if @get('content.sex') == GG.MALE then "father" else "mother"
  ).property('content')
  gametes: null
  sistersHidden: true
  animate: ->
    console.log "animating"
    GG.animateMeiosis(".meiosis." + @get('motherFather'), this)
  crossOver: ->
    console.log "crossing over"
    @set 'gametes', @get('content.biologicaOrganism').createGametesWithCrossInfo(4)[0]
  randomGameteNumber: (->
    ExtMath.randomInt(4)
  ).property('gametes')
  chosenGamete: (->
    return @get('gametes').cells[@get('randomGameteNumber')]
  ).property('gametes','randomGameteNumber')
  chosenGameteAlleles: (->
    chosen = @get('chosenGamete')
    side = if @get('content.sex') == GG.MALE then 'b' else 'a'
    alleles = ""
    for c in ['1','2','XY']
      alleles += side + ":" + chosen[c].reduce (prev, item) ->
        return prev + "," + side + ":" + item
    return alleles
  ).property('chosenGamete')
