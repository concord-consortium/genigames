minispade.require 'genigames/view-mixins'
minispade.require 'genigames/meiosis-animation'

GG.LoginView = Ember.View.extend
  templateName: 'login'
  username: ""
  password: ""
  loggingInBinding: 'GG.sessionController.loggingIn'
  errorBinding: 'GG.sessionController.error'
  firstTimeBinding: 'GG.sessionController.firstTime'
  waitingForPreloadBinding: 'GG.sessionController.waitingForPreload'
  login: ->
    pw = @get('password')
    @set('password', "")
    data = {username: @get('username'), password: pw}
    GG.statemanager.send 'login', data

GG.LogoutButton = Ember.View.extend
  tagName: 'div'
  classNames: 'logout'
  template: Ember.Handlebars.compile('<div>Logout</div>')
  click: ->
    GG.statemanager.transitionTo 'loggingOut'

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
  classNameBindings: ['icon','location','enabled']
  attributeBindings: ['style']
  location: "location"
  icon: (->
    @get('content.icon')
  ).property('content.icon')
  enabledBinding: 'content.enabled'
  style: (->
    # TODO how do we do width and height?
    width = 175
    height = 125
    a = 356
    b = 356
    r = 253
    # adjust the radius to be a little bigger because the center of the town icons cannot be in the edge of the world
    # instead, each town icon image should have the "bottom" exactly at 15 pixels higher than the bottom of the image
    r = r + (height/2)
    r = r - 15
    # calculate the position of the town based on the position
    # with the center at a,b, r = radius, t = angle:
    # (a + r cos t, b + r sin t)
    # add 90 since the equation assumes 0 is on the right of the circle, not top
    # subtract because the coordinate
    posRadX = (@get('content.position') + 90) * (Math.PI/180)
    # subtract for Y since the coordinate system is mirrored on the Y-axis
    posRadY = (@get('content.position') - 90) * (Math.PI/180)
    x = Math.round(a + (r * Math.cos(posRadX)) - (width/2))
    y = Math.round(b + (r * Math.sin(posRadY)) - (height/2))
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
  breedTypeBinding: 'GG.breedingController.breedType'

GG.DrakeView = Ember.View.extend
  templateName       : 'drake'
  drakeImageName     : (->
    color = @get('org').getCharacteristic 'color'
    GG.getFileName(color, "png")
  ).property()
  drakeImage         : (->
    '../images/drakes/' + @get 'drakeImageName'
  ).property('drakeImage')
  drakeIdleImage     : (->
    '../images/drakes/headturn/' + @get 'drakeImageName'
  ).property('drakeImage')
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
  armor : (->
    armor = @get('org').getCharacteristic "armor"
    if armor is "Armor"
      'drake-armor'
    else 'drake-no-armor'
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
    if horns is "Forward horns"
      'drake-forward-horns'
    else 'drake-reverse-horns'
  ).property()
  fire : (->
    fire = @get('org').getCharacteristic "fire breathing"
    if fire is "Fire breathing"
      'drake-fire'
    else 'trait-absent'
  ).property()
  maleSpots : (->
    sex = if @get('content.sex') is GG.FEMALE then "female" else "male"
    if sex is "male"
      'drake-male-spots'
    else 'trait-absent'
  ).property()
  didInsertElement: ->
    # Wait for the animation images to load, then move it in place and start it up
    swapImage = =>
      GG.breedingController.removeObserver 'isShowingBreeder', swapImage
      layer = '#' + @get('elementId')
      $(layer + ' .drake-idle-img').imagesLoaded =>
        $(layer + ' .static').css({left: 400})
        $(layer + ' .idle').css({left: 0})
        @setNextIdleInterval()

    if GG.breedingController.get 'isShowingBreeder'
      swapImage()
    else
      GG.breedingController.addObserver 'isShowingBreeder', swapImage

  setNextIdleInterval: ->
    nextTime = 3000 + Math.random() * 15000
    setTimeout =>
      @idleAnimation()
      @setNextIdleInterval()
    , nextTime
  idleAnimation: ->
    if !@$('img')
      return
    GG.animateDrake @$('.drake-idle-img')

# Here we create one single animation timer, and add new images
# to an array so we can animate multiple drakes at once without
# creating a separate timer for each
GG.animateDrake = ($img) ->
  if GG.drakeAnimationList.length > 1 then return

  GG.drakeAnimationList.push $img
  GG.drakeAnimationPositions.push 0
  GG.drakeAnimationLengths.push 15  # for the moment we assume animations are 15 frames
  if !GG.drakeAnimationTimer
    GG.drakeAnimationTimer = setInterval =>
      i = GG.drakeAnimationList.length
      if i is 0
        clearInterval GG.drakeAnimationTimer
        GG.drakeAnimationTimer = null
        return
      while (i--)
        pos = GG.drakeAnimationPositions[i] = GG.drakeAnimationPositions[i] + 1
        if pos >= GG.drakeAnimationLengths[i]
          GG.drakeAnimationList[i].css({left:"0%"})
          GG.drakeAnimationList.splice(i, 1)
          GG.drakeAnimationPositions.splice(i, 1)
          GG.drakeAnimationLengths.splice(i, 1)
        else
          GG.drakeAnimationList[i].css({left:"-"+(pos*100)+"%"})
    , 83  # ~ 12 fps

GG.drakeAnimationList = []
GG.drakeAnimationPositions = []
GG.drakeAnimationLengths = []

GG.drakeAnimationTimer = null

# getFileName("Shiny red", "png") -> "shinyRed.png"
GG.getFileName = (str, ext) ->
  str = str.replace(/(?:^\w|[A-Z]|\b\w)/g, (letter, index) ->
    if index == 0 then letter.toLowerCase() else letter.toUpperCase()
  ).replace(/\s+/g, '')
  str + "." + ext

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

GG.BreedButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: "Produce an offspring drake from the current parents"

  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'

  classNameBindings : ['enabled']
  enabled: (->
    !!(this.get('mother') && this.get('father'))
  ).property('mother', 'father')

  click: ->
    GG.statemanager.send('breedDrake')

GG.MeiosisButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  showToolTip: (->
    GG.breedingController.get('breedType') is GG.BREED_AUTOMATED
  ).property('GG.breedingController.breedType')
  toolTipText: "Enable manual control of meiosis."
  costPropertyName: 'meiosisControlEnabled'
  click: ->
    GG.statemanager.send('toggleBreedType')

GG.AlleleView = Ember.View.extend GG.PointsToolTip,
  classNameBindings: ['defaultClassNames', 'revealable', 'dominant', 'gene']
  defaultClassNames: 'allele'
  valueBinding: 'content.allele'
  hiddenValue: (->
    value = @get 'value'
    if value is "Tk" then value = "T"
    if value is "A1" or value is "A2" then value = "A"
    value = value.charAt(0).toUpperCase() + value.slice(1)
    value + '?'
  ).property('value').cacheable()
  clickable: true
  hidden: Ember.computed.not('content.visible')
  revealable: (->
    return @get('hidden') and @get('clickable')
  ).property('hidden','clickable')
  dominant: (->
    ending = @get('displayValue').slice(-1)
    if ending is "1"
      return "dominant"
    else if ending is "2"
      return "recessive"
    else if ending is "3"
      return "recessive3"
    else
      return ""
  ).property('displayValue')
  gene: (->
    if @get('value')?
      return BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, @get('value')).name
    else
      return ''
  ).property('value')
  displayValue: (->
    if @get('hidden') then @get('hiddenValue') else @get('value')
  ).property('value','hidden')

  showToolTipBinding: 'revealable'
  toolTipText: "Reveal hidden allele."
  costPropertyName: 'alleleRevealed'

GG.ChromoView = Ember.View.extend
  templateName: 'chromosome'
  content: null
  chromo: '1'
  side: 'a'
  sister: null
  crossoverSelectable: false
  selectable: false
  selected: false
  hiddenGenesBinding: 'GG.drakeController.hiddenGenes'
  visibleGenesBinding: 'GG.drakeController.visibleGenes'
  revealedContentAllelesIdxBinding: 'content.revealedIdx'
  revealedAlleles: null
  gametes: null
  useGamete: false
  realSide: (->
    realSide = ''
    if ['x2','y','b'].contains(@get('side'))
      realSide = 'b'
    else
      realSide = 'a'

    realSide += @get('sister')
    return realSide
  ).property('sister','side')
  cellNum: (->
    if @get('gametes')?
      endInfo = @get('gametes').endCellInfo

      chromo = @get('chromo')
      chromo = if chromo == "X" or chromo == "Y" then "XY" else chromo

      cellNum = endInfo[chromo][@get 'realSide']
    else
      cellNum = -1

    return cellNum
  ).property('chromo','realSide','gametes')
  gamete: (->
    if @get('cellNum') != -1
      cell = @get('gametes').cells[@get('cellNum')]
      chromo = @get 'chromo'
      chromo = if chromo == 'X' or chromo == 'Y' then 'XY' else chromo
      return cell[chromo]
    else
      return null
  ).property('gametes','chromo','cellNum')
  visibleGamete: (->
    @_filterGamete('gamete',false)
  ).property('gamete', 'visibleGenes')
  hiddenGamete: (->
    @_filterGamete('gamete',true)
  ).property('gamete', 'hiddenGenes')
  _filterGamete: (prop, hidden)->
    res = null
    if @get(prop)?.alleles
      gamete = @get(prop)
      genesProp = if hidden then 'hiddenGenes' else 'visibleGenes'
      genes = @get(genesProp) || []
      res = GG.Genetics.filter(gamete.alleles, genes)
      # Now add or subtract the revealed alleles from the result
      if gamete.revealed?
        if hidden
          res = res.filter (item)->
            return !gamete.revealed.contains(item)
        else
          res = res.concat(gamete.revealed).uniq().compact()
    return res
  biologicaChromoName: (->
    chromo = @get 'chromo'
    return chromo unless chromo is "X" or chromo is "Y"
    return "XY"
  ).property('chromo')
  genes: (->
    GG.Genetics.species.chromosomeGeneMap[@get 'biologicaChromoName']
  ).property('chromo')
  visibleAlleles: (->
    return @_getAlleles(false)
  ).property('chromo','content','side','visibleGamete','revealedAlleles','revealedContentAllelesIdx','useGamete')
  hiddenAlleles: (->
    return @_getAlleles(true)
  ).property('chromo','content','side','hiddenGamete','revealedAlleles','revealedContentAllelesIdx','useGamete')
  alleles: (->
    bioChromo = @get('content.biologicaOrganism').genetics.genotype.chromosomes["1"]["a"]
    vis = @get('visibleAlleles').map (item)->
      {allele: item, visible: true, position: bioChromo.getAllelesPosition(item)}
    hid = @get('hiddenAlleles').map (item)->
      {allele: item, visible: false, position: bioChromo.getAllelesPosition(item)}

    alleles = vis.concat(hid)
    alleles = alleles.sort (a,b)=>
      if a.position > b.position then 1 else -1
    return alleles
  ).property('visibleAlleles','hiddenAlleles')
  _getAlleles: (hidden)->
    gamete = if hidden then 'hiddenGamete' else 'visibleGamete'
    res = []
    if (@get 'content')? or (@get gamete)?
      if @get('useGamete') && (@get gamete)?
        res = @get gamete
      else
        prop = if hidden then 'content.hiddenGenotype' else 'content.visibleGenotype'
        fullGeno = @get prop
        side = @get 'side'
        if ['x2','y'].contains(side)
          side = 'b'
        else if side is 'x1'
          side = 'a'
        geno = fullGeno[side]
        res = GG.Genetics.filter(geno, @get 'genes')
    return res
  click: ->
    if @get('selectable')
      # toggle selected
      if @get('selected')
        @set('selected', false)
        GG.statemanager.send 'deselectedChromosome', this
      else
        @set('selected', true)
        GG.statemanager.send 'selectedChromosome', this
  allelesClickable: true
  alleleClicked: (event) ->
    if @get('allelesClickable')
      allele = event.context
      if !allele.visible
        @get('content').markRevealed(@get('side'), allele.allele)
        GG.userController.addReputation -GG.actionCostsController.getCost 'alleleRevealed'
        GG.logController.logEvent GG.Events.REVEALED_ALLELE
          allele: allele.allele
          side: @get('side')
          drake: { alleles: @get('content.biologicaOrganism.alleles')
          sex: @get('content.sex') }
  defaultClass: 'chromosome'
  chromoName: (->
    'chromo-'+@get('chromo')
  ).property('chromo','side')
  right: (->
    if @get('chromo') == 'Y' or ['b','y','x2'].contains(@get('side')) then "right" else "left"
  ).property('chromo','side')
  parent: (->
    if ['a','x1'].contains(@get('side')) then 'mother' else 'father'
  ).property('chromo','side')
  sisterClass: (->
    if (@get 'sister')?
      return "sister-" + @get('sister')
    else
      return ""
  ).property('sister')
  cell: (->
    cellNum = @get('cellNum')
    if cellNum == -1
      return ''
    else
      return 'cell' + cellNum
  ).property('cellNum')
  hidden: false
  classNames: ['chromosome']
  classNameBindings: ['chromoName', 'right', 'parent', 'sisterClass', 'hidden', 'cell', 'selectable', 'selected']

GG.ChromosomePanelView = Ember.View.extend
  templateName: 'chromosome-panel'
  hiddenBinding: 'controller.hidden'
  defaultClass: 'chromosome-panel'
  chromosomeClass: (->
    if @get('controller.selected.sex') is GG.FEMALE then 'female-chromosome'
    else 'male-chromosome'
  ).property('controller.selected').cacheable()
  classNameBindings: ['hidden','defaultClass', 'chromosomeClass']

GG.CrossoverPointView = Ember.View.extend
  tagName: 'div'
  classNames: ['crossoverPoint','hidden']
  classNameBindings: ['gene']
  allele: null
  chromoView: null
  gene: (->
    return BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, @get('allele'))?.name
  ).property('allele')
  click: ->
    GG.statemanager.send 'selectedCrossover', {chromoView: @get('chromoView'), allele: @get('allele')}

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

GG.OffspringUseButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: "Submit the current drake as the solution to this task"
  classNames : 'offspring-buttons-use'
  click: ->
    GG.statemanager.send('submitOffspring')

GG.OffspringSaveButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: "Use this drake as a parent"
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
    text = @get('currentTask.npc.speech.shortText') || @get('currentTask.npc.speech.text') || ""
    if typeof(text) == 'object'
      # This results in some pretty ugly text...
      # but we only use this if shortText isn't defined.
      text = text.reduce (prev, item, idx, arr)->
        return prev + " " + item
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
    currentText = authoredText[@get 'textIdx']
    currentText = currentText.replace(/\[(.*?)\]/g, "") # rm button text
    return new Handlebars.SafeString(currentText)
  ).property('content','textIdx')
  isLastText: (->
    return @get('textIdx') >= @get('lastTextIdx')
  ).property('textIdx','lastTextIdx')
  resetTextIdx: (->
    @set 'textIdx', 0
    authoredText = @get 'content.npc.speech.text'
    @set 'lastTextIdx', (authoredText.length - 1)
  ).observes('content')
  continueButtonText: (->
    authoredText = @get 'content.npc.speech.text'
    currentText = authoredText[@get 'textIdx']
    buttonText = /\[(.*?)\]/g.exec(currentText)
    if (buttonText)
      return buttonText[1]
    return "Continue"
  ).property('content','textIdx')
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
  init: ->
    @_super()
    if @get('content')?
      @contentChanged()
  contentChanged: (->
    GG.meiosisController.set(@get('motherFather') + "View", this)

    @_createGametes()
  ).observes('content')
  classNames: ['meiosis']
  classNameBindings: ['motherFather']
  motherFather: (->
    if @get('content.sex') == GG.MALE then "father" else "mother"
  ).property('content')
  gametes: null
  useGametes: false
  rerender: ->
    @_super()
    setTimeout =>
      @set('useGametes', false)
      GG.meiosisController.set(@get('motherFather') + "View", _this)
    , 200
  _createGametes: ->
    doCrossover = if GG.breedingController.get('breedType') == GG.BREED_CONTROLLED then false else true
    newGametes = @get('content.biologicaOrganism').createGametesWithCrossInfo(4, doCrossover)[0]
    @set 'gametes', newGametes
    return newGametes
  sistersHidden: true
  animate: (callback)->
    newGametes = @_createGametes()

    # Transfer revealed status to new gametes... We can't do this earlier
    # because the meiosis view is created when the user selects the drake
    # and still has an opportunity to interact and reveal alleles before
    # the animation starts.
    revealed = @get('content.revealedAlleles')
    normalizedSide = (s)->
      if ['x','x1','a'].contains(s)
        return 'a'
      else if ['y','x2','b'].contains(s)
        return 'b'
    for side of revealed
      alleles = revealed[side]
      continue if alleles.length == 0
      nSide = normalizedSide(side)
      for i in [0...newGametes.cells.length]
        gamete = newGametes.cells[i]
        for c in ["1","2","XY"]
          chromo = gamete[c]
          for j in [0...alleles.length]
            allele = alleles[j]
            idx = chromo.alleles.indexOf(allele)
            if idx != -1 and normalizedSide(chromo.allelesWithSides[idx].side) is nSide
              chromo.revealed ?= []
              chromo.revealed.push allele

    GG.MeiosisAnimation.animate(".meiosis." + @get('motherFather'), this, callback)
  resetAnimation: ()->
    GG.MeiosisAnimation.reset(".meiosis." + @get('motherFather'), this)
    @set('gametes', null)
  crossOver: ->
    newGametes = @get('gametes')
    # Move the allele circles, then reset them back and set the gametes at the same time
    cells = newGametes.cells

    # moves is a data structure that outlines what is moving from where to where
    # {
    #   "gene": {[to]: [from], [to]: [from], ...}
    # }
    moves = {}
    for own chr,crosses of newGametes.crossInfo
      continue unless crosses?
      for c in [0...crosses.length]
        cross = crosses[c]
        startingAlleles = cross.crossedAlleles
        if startingAlleles?
          for a in [0...startingAlleles.length]
            sAllele = startingAlleles[a][0]
            gene = BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, sAllele).name
            moves[gene] ?= {}
            end = moves[gene][cross.start_cell]
            end = cross.start_cell unless end?
            start = moves[gene][cross.end_cell]
            start = cross.end_cell unless start?
            moves[gene][cross.end_cell] = end
            moves[gene][cross.start_cell] = start
    @animateMoves moves, =>
      @set('useGametes', true)

  animateMoves: (moves, callback)->
    animationQueue = []
    selectorBase = "#" + @get('elementId')
    for own gene,swaps of moves
      for own dest,source of swaps
        sourceSelector = selectorBase + " .cell" + source + " .allele." + gene
        destSelector = selectorBase + " .cell" + dest + " .allele." + gene

        s = $(sourceSelector)
        d = $(destSelector)

        sOffset = s.offset()
        dOffset = d.offset()
        continue unless sOffset? and dOffset?

        dx = dOffset.left - sOffset.left
        dy = dOffset.top - dOffset.top

        leftShift = (if dx > 0 then "+=" else "-=") + Math.abs(dx) + "px"
        topShift = (if dy > 0 then "+=" else "-=") + Math.abs(dy) + "px"

        animationQueue.push {source: sourceSelector, anim: {top: dy, left: dx}}

    # temporarily put alleles on top, so we don't see them sliding under other chromosomes
    $(selectorBase + " .allele").css({"z-index": 10})
    for i in [0...animationQueue.length]
      anim = animationQueue[i]
      $(anim.source).animate(anim.anim, 1500, 'easeInOutQuad')

    setTimeout =>
      callback()
      Ember.run.next this, =>
        for i in [0...animationQueue.length]
          anim = animationQueue[i]
          $(anim.source).css({left: '', top: ''})
      # put the alleles back at their default level, so they slide under/over
      $("#" + @get('elementId') + " .allele").css({"z-index": ''})
    , 1550
  allelesClickable: false
  crossoverSelectable: false
  chromosomesSelectable: false
  selectingChromatids: (callback)->
    @set('chromosomesSelectable', true)
    GG.statemanager.send 'selectingChromatids', {elementId: @get('elementId'), callback: callback}
  doneSelectingChromatids: ->
    @set('chromosomesSelectable', false)
    GG.statemanager.send 'doneSelectingChromatids', this
  selectingCrossover: (callback)->
    @set('crossoverSelectable', true)
    @set('useGametes', true)
    GG.statemanager.send 'selectingCrossover', {elementId: @get('elementId'), callback: callback}
  doneSelectingCrossover: ->
    @set('crossoverSelectable', false)
    GG.statemanager.send 'doneSelectingCrossover', this
  randomGameteNumberOverride: -1
  randomGameteNumber: (->
    override = @get('randomGameteNumberOverride')
    if override == -1
      return ExtMath.randomInt(4)
    else
      return override
  ).property('gametes', 'randomGameteNumberOverride')
  chosenSex: (->
    if @get('content.sex') == GG.MALE and @get('chosenGamete')? and @get('chosenGamete').XY.side is 'y' then GG.MALE else GG.FEMALE
  ).property('gametes','randomGameteNumber')
  chosenGamete: (->
    return null unless @get('gametes')?
    return @get('gametes').cells[@get('randomGameteNumber')]
  ).property('gametes','randomGameteNumber')
  chosenGameteAlleles: (->
    chosen = @get('chosenGamete')
    return "" unless chosen?
    side = if @get('content.sex') == GG.MALE then 'b' else 'a'
    alleles = ""
    for c in ['1','2','XY']
      chromoAlleles = chosen[c].alleles
      if chromoAlleles? and chromoAlleles.length > 0
        alleles += "," + side + ":" + chromoAlleles.reduce (prev, item) ->
          return prev + "," + side + ":" + item
    return alleles.slice(1)
  ).property('chosenGamete')

GG.ObstacleCourseView = Ember.View.extend
  templateName: 'obstacle-course'
  tagName: 'div'
  classNames: ['obstacle-course']
  classNameBindings: ['hidden']
  obstaclesBinding: 'GG.obstacleCourseController.obstacles'
  drakeBinding: 'GG.obstacleCourseController.drake'
  hiddenBinding: 'GG.obstacleCourseController.hidden'
  start: ->
    # TODO We might want to write our own easing function to replace 'linear', which
    # could speed up/slow down the progress over various obstacles depending on
    # drake characteristics.
    $('.obstacle-course .obstacles').animate({left: "-=400px"}, 10000, 'linear')
    $('.obstacle-course .background').animate({left: "-=400px"}, 10000, 'linear')
    $('.obstacle-course .drake-container').animate({left: "+=800px"}, 10000, 'linear')
  reset: ->
    $('.obstacle-course .obstacles').css({left: ""})
    $('.obstacle-course .background').css({left: ""})
    $('.obstacle-course .drake-container').css({left: ""})
  done: ->
    GG.statemanager.transitionTo 'inTown'

GG.ObstacleView = Ember.View.extend
  tagName: 'div'
  classNames: ['obstacle']
  classNameBindings: ['type']
  type: "ducks"


