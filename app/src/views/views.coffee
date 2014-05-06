minispade.require 'genigames/views/view-mixins'
minispade.require 'genigames/views/drake-view'
minispade.require 'genigames/views/meiosis-animation'

GG.LoginView = Ember.View.extend
  templateName: 'login'
  username: ""
  password: ""
  loggingInBinding: 'GG.sessionController.loggingIn'
  errorBinding: 'GG.sessionController.error'
  firstTimeBinding: 'GG.sessionController.firstTime'
  waitingForPreloadBinding: 'GG.sessionController.waitingForPreload'
  registeredUsernameBinding: 'GG.sessionController.registeredUsername'
  login: ->
    pw = @get('password')
    @set('password', "")
    username = @get('username') or $('#username-field input').attr('value')
    data = {username: username, password: pw}
    GG.statemanager.send 'login', data
  register: ->
    GG.statemanager.send 'register'

GG.LogoutButton = Ember.View.extend
  tagName: 'div'
  classNames: 'logout'
  template: Ember.Handlebars.compile('<div>Logout</div>')
  click: ->
    GG.statemanager.transitionTo 'loggingOut'

GG.GoToTownButton = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  classNames: 'goToTown'
  toolTipText: "Reset task and go back to town"
  isShowingBreederBinding: 'GG.breedingController.isShowingBreeder2'
  hidden: (->
    not @get('isShowingBreeder')
  ).property('isShowingBreeder')
  classNameBindings: ['hidden']
  click: ->
    GG.statemanager.send 'goToTown'

GG.GoToWorldButton = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  classNames: 'goToWorld'
  toolTipText: "Click to leave the town"
  click: ->
    GG.statemanager.send 'goToWorld'

GG.BackToTaskListButton = Ember.View.extend
  tagName: 'div'
  classNames: 'task-list'
  template: Ember.Handlebars.compile('<div>Challenge List</div>')
  click: ->
    GG.statemanager.transitionTo 'inTaskList'

GG.ChooseClassView = Ember.View.extend
  templateName: 'choose-class'
  optionsBinding: 'GG.sessionController.classesWithLearners'
  clazz: null
  choose: ->
    GG.statemanager.send 'chooseLearner', @get('clazz')

GG.DefineGroupsView = Ember.View.extend
  tagName: 'div'
  elementId: 'define-groups'
  templateName: 'define-groups'
  groupsBinding: 'GG.groupsController.groups'
  errorBinding: 'GG.groupsController.error'
  removeUser: (evt)->
    GG.groupsController.removeUser(evt.context)
  addUser: ->
    GG.groupsController.addUser()
  done: ->
    console.log("done called")
    GG.groupsController.verifyContent()
    unless GG.groupsController.get('error')
      GG.statemanager.send 'definedGroups'

GG.WorldView = Ember.View.extend
  templateName: 'world'
  contentBinding: 'GG.townsController'

GG.WorldTownView = Ember.View.extend
  classNameBindings: ['icon','location','enabled','completed','locked']
  attributeBindings: ['style']
  location: "location"
  icon: (->
    @get('content.icon')
  ).property('content.icon')
  enabledBinding: 'content.enabled'
  completedBinding: 'content.completed'
  locked: (->
    @get('content.locked') and not @get('content.enabled')
  ).property('content.locked', 'content.enabled')
  style: (->
    # width and height are always set to 175x125 regardless of the icon size (image is always centered in this box).
    width = 175
    height = 125
    a = 216    # x position of the center of the world (relative to the world div)
    b = 216    # y position of the center of the world (relative to the world div)
    r = 216
    n = 28     # n is the number to adjust the icon in the world
    # adjust the radius to be a little bigger because the center of the town icons cannot be in the edge of the world
    # instead, each town icon image should have the "bottom" exactly at n pixels higher than the bottom of the image
    r = r + (height/2)
    r = r - n
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
  isBaselineBinding: 'GG.baselineController.isBaseline'
  hasObstacleCourseBinding: 'GG.obstacleCourseController.hasObstacleCourse'
  baseline: (->
    if @get('isBaseline') then "baseline" else "game"
  ).property('isBaseline')
  meiosisEnabledBinding: 'GG.tasksController.meiosisControlEnabled'
  showAllTraits: (->
    townId = GG.townsController.get("content").indexOf GG.townsController.get "currentTown"
    return (townId > 1)
  ).property('GG.townsController.currentTown')

GG.TraitSelectionView = Ember.View.extend GG.PointsToolTip,
  templateName: 'trait-selection'
  showAllTraits: (->
    townId = GG.townsController.get("content").indexOf GG.townsController.get "currentTown"
    return (townId > 1)
  ).property('GG.townsController.currentTown')
  toolTipText: "Use the buttons to keep track of the traits you are breeding for"
  toolTipConfigTooltip: 'bottomRight'
  toolTipConfigTip: 'bottomRight'
  characteristicSelected: (evt) ->
    elem = evt.currentTarget
    container = elem.parentElement
    characteristic = ""+evt.context

    wasSelected = $(elem).hasClass("selected")

    $(container).find(".characteristic").removeClass("selected")
    $(elem).addClass("selected") unless wasSelected

    GG.logController.logEvent (unless wasSelected then GG.Events.SELECTED_CHARACTERISTIC else GG.Events.DESELECTED_CHARACTERISTIC),
          trait: container.classList[1]
          characteristic: characteristic

    GG.statemanager.send 'selectTrait', characteristic

  traits: (->
    initialTraits =
      [
        {trait: "gender",    characteristics: ["male", "female"]}
        {trait: "wings",     characteristics: ["wings", "no-wings"]}
        {trait: "metallic",  characteristics: ["metallic", "non-metallic"]}
        {trait: "horns",     characteristics: ["reverse-horns", "forward-horns"]}
        {trait: "fire",      characteristics: ["no-fire", "fire"]}
      ]
    if !@get 'showAllTraits'
      return initialTraits
    else
      return initialTraits.concat [
          {trait: "color",    characteristics: ["green", "purple", "blue", "red"]}
          {trait: "spikes",     characteristics: ["wide-spikes", "medium-spikes", "narrow-spikes"]}
          {trait: "tail",  characteristics: ["short-tail", "kinked-tail", "long-tail"]}
          {trait: "armor",     characteristics: ["armor", "no-armor"]}
        ]
  ).property('showAllTraits')

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
  toolTipText: (->
    tip = "Produce an offspring %@ from the current parents".fmt(Ember.I18n.t('drake'))
  ).property()
  costPropertyName: 'extraBreedCycle'

  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'

  classNameBindings : ['enabled']
  inAnimationBinding: 'GG.meiosisController.inAnimation'
  canBreedDuringAnimationBinding: 'GG.meiosisController.canBreedDuringAnimation'
  enabled: (->
    if !this.get('mother') || !this.get('father')
      return false
    else if @get('inAnimation') && !@get('canBreedDuringAnimation')
      return false
    else
      return true
  ).property('mother', 'father', 'inAnimation', 'canBreedDuringAnimation')

  click: ->
    if @get 'enabled'
      GG.statemanager.send('breedDrake')

GG.AlleleView = Ember.View.extend GG.PointsToolTip,
  classNameBindings: ['defaultClassNames', 'revealable', 'dominant', 'gene', 'species']
  defaultClassNames: 'allele'
  valueBinding: 'content.allele'
  species: (->
    GG.DrakeSpecies.name
  ).property()
  hiddenValue: (->
    value = @get 'value'
    value.charAt(0) + "?"
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
  allelesClickableDefault: true
  allelesClickable: (->
    return @get('allelesClickableDefault') and GG.baselineController.get('isNotBaseline')
  ).property('allelesClickableDefault','GG.baselineController.isNotBaseline')
  alleleClicked: (event) ->
    if @get('allelesClickable')
      allele = event.context
      if !allele.visible
        @get('content').markRevealed(@get('side'), allele.allele)
        GG.reputationController.subtractReputation(GG.actionCostsController.getCost('alleleRevealed'), GG.Events.REVEALED_ALLELE)
        GG.logController.logEvent GG.Events.REVEALED_ALLELE,
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
  classNameBindings: ['gene','species']
  allele: null
  chromoView: null
  gene: (->
    return BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, @get('allele'))?.name
  ).property('allele')
  species: (->
    GG.DrakeSpecies.name
  ).property()
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

GG.OffspringBackButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: "Pick new parents"
  classNames : 'offspring-buttons-back'
  click: ->
    GG.statemanager.send('selectParents')

GG.OffspringUseButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: (->
    "Submit the current %@ as the solution to this task".fmt(Ember.I18n.t('drake'))
  ).property()
  classNames : 'offspring-buttons-use'
  click: ->
    GG.statemanager.send('submitOffspring')

GG.OffspringSaveButtonView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  toolTipText: (->
    if !GG.breedingController.get 'childSavedToParents'
      "Use this %@ as a parent".fmt(Ember.I18n.t('drake'))
    else
      "Already saved this %@! Press the Back button to select parents.".fmt(Ember.I18n.t('drake'))
  ).property('GG.breedingController.childSavedToParents')
  classNames : 'offspring-buttons-save'
  classNameBindings: ['disabled']
  disabled: (->
    !GG.powerUpController.hasPowerup("backcrossing") or GG.breedingController.get('childSavedToParents')
  ).property('GG.breedingController.childSavedToParents')
  click: ->
    @set 'disabled', true
    GG.statemanager.send('saveOffspring')

GG.ValueCounter = Ember.View.extend GG.PointsToolTip,
  templateName: 'move-counter'
  classNames: ['value-counter']
  toolTipText: "This is the amount you're being offered for breeding the target drake"
  toolTipConfigTarget: 'topMiddle'
  toolTipConfigTooltip: 'bottomRight'
  toolTipConfigTip: 'bottomRight'

GG.MoveCounter = Ember.View.extend GG.PointsToolTip,
  templateName: 'move-counter'
  classNames: ['cost-counter']
  toolTipText: "This tracks how much you have spent to breed, select chromosomes, and do crossovers"

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
  backgroundBinding: 'GG.townsController.currentTown.background'

GG.TaskNPCView = Ember.View.extend
  tagName            : 'div'
  classNames         : ['npc']
  classNameBindings  : ['npcLocationState','hidden']
  attributeBindings  : ['style']
  hidden: (->
    !(@get('content.completed') || @get('content.showInForeground') )
  ).property('content.completed', 'content.showInForeground')
  style: (->
    return "" if @get('content.showInForeground')

    scale = @get('content.npc.scale') || 0.5
    layer = @get('content.npc.layer') || 1
    flip  = @get('content.npc.flip') || false

    if flip then xModifier = -1 else xModifier = 1

    style =  "top: " + @get('content.npc.position.y') + "px; left: " + @get('content.npc.position.x') + "px;"
    style += "z-index: #{layer-1};"
    for vendor in ["-webkit-", "-moz-", "-ms-", "-o-", ""]
      style += "#{vendor}transform: scaleX(#{scale * xModifier}) scaleY(#{scale});"
      style += "#{vendor}transform-origin: 0 0;"

    return style

  ).property('content.npc.position.x','content.npc.position.y', 'content.npc.position.scale','content.showInForeground')
  npcLocationState: (->
    if @get('content.showInForeground') then @get('content.foregroundLocation') else "background"
  ).property('content.showInForeground')
  npcSelected: (evt) ->
    GG.statemanager.send 'npcSelected', evt.context
  replayTask: (evt) ->
    GG.statemanager.send 'replayTask', evt.context

GG.NPCView = Ember.View.extend GG.PointsToolTip,
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
  mouseEnter: ->
    # stop(true, true) is necessary so that we don't end up with a slowly enlarging/shrinking image...
    @$().stop(true, true).animate({width: "+=20px", height: "+=17px", top: "-=10px", left: "-=8px"}, 100, 'easeOutCubic')
  mouseLeave: ->
    @$().stop(true, true).animate({width: "-=20px", height: "-=17px", top: "+=10px", left: "+=8px"}, 100, 'easeOutCubic')

GG.NPCSpeechBubbleView = Ember.View.extend
  tagName            : 'div'
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showSpeechBubble')
  init               : ->
    @_super()
  currentText        : (->
    if @get 'isShowingEndMessage'
      text = @get 'content.npc.speech.completionText'
    else if @get 'isShowingThanksMessage'
      text = "Thanks again!"
    else if @get 'isShowingFailMessage'
      text = @get('content.npc.speech.failText') || "That's not the drake I'm looking for!"
    else
      text = @get 'content.npc.speech.text'
    if typeof text == "string" then text else text[0]
  ).property('content.npc.speech.text', 'isShowingEndMessage', 'isShowingThanksMessage', 'isShowingFailMessage')
  text               : (->
    currentText = @get 'currentText'
    text = currentText.replace(/\[(.*?)\]/g, "") # rm button text
    return new Handlebars.SafeString(text)
  ).property('currentText')
  continueButtonText: "Continue"
  acceptText: (->
    @get('content.npc.speech.accept') || "Sure"
  ).property('content.npc.speech.accept')
  declineText: (->
    @get('content.npc.speech.decline') || "Maybe later"
  ).property('content.npc.speech.decline')
  isShowingEndMessageBinding: 'content.isShowingEndMessage'
  isShowingThanksMessageBinding: 'content.isShowingThanksMessage'
  isShowingFailMessageBinding: 'content.isShowingFailMessage'
  accept: ->
    GG.statemanager.send 'accept', @get 'content'
  decline: ->
    GG.statemanager.send 'decline'
  replay: ->
    GG.statemanager.send 'replay', @get 'content'
  done: ->
    GG.statemanager.send 'done'

GG.NPCHeartBubbleView = Ember.View.extend GG.PointsToolTip,
  templateName       : 'heart-bubble'
  classNames         : ['heart-wrapper']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.completed')
  toolTipConfigTarget:  'bottomLeft'
  toolTipConfigTooltip: 'bottomRight'
  toolTipConfigTip   :  'bottomRight'
  toolTipText: (->
    if GG.tooltipController.get 'show'
      "Replay: #{@get('content.targetDrake')}<br>Hearts show gratitude for a correctly bred drake.
      If the heart is not completely full, it means you can earn more by trying again and breeding more efficiently."
    else
      "Replay: " + @get('content.targetDrake')
  ).property('content', 'GG.tooltipController.show')
  forceTooltip: true
  updateHeartFill: (->
    score = @get('content.reputationEarned') / @get('content.reputationFullScore')
    height = 53 - (score * 37)    # height is from top, min 53px, max 16px
    height = 16 if height < 16
    height = 53 if height > 53
    @$('.heart-bubble-empty-wrapper').css({height: height})
  ).observes('content.reputationEarned')
  mouseEnter: ->
    # stop(true, true) is necessary so that we don't end up with a slowly enlarging/shrinking image...
    @$('img').stop(true, true).animate({width: "+=4px", height: "+=4px", top: "-=2px", left: "-=2px"}, 100, 'easeOutCubic')
  mouseLeave: ->
    @$('img').stop(true, true).animate({width: "-=4px", height: "-=4px", top: "+=2px", left: "+=2px"}, 100, 'easeOutCubic')

GG.NPCFinalMessageBubbleView = Ember.View.extend
  tagName            : 'div'
  text               : (->
    return new Handlebars.SafeString(GG.townsController.get("currentTown.finalMessage"))
  ).property('content')
  classNames         : ['speech-bubble']
  classNameBindings  : ['hidden']
  hidden             : Ember.computed.not('content.showFinalMessageBubble')
  isFinalTaskBinding : 'content.finalTask'
  next: ->
    GG.statemanager.transitionTo 'inWorld.movingDirectlyToNextTown'
  world: ->
    @set 'content.showFinalMessageBubble', false
    GG.statemanager.transitionTo 'inWorld.townsWaiting'
  dismissFinalBubble: ->
    @set 'content.showFinalMessageBubble', false
    $('.goToWorld').mouseover()
    setTimeout (-> $('.goToWorld').qtip("hide")), 2500

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
  currentTownBinding: 'GG.townsController.currentTown'
  crossoverCost: (->
    GG.actionCostsController.getCost('crossoverMade')
  ).property('currentTown')
  chromosomeSelectedCost: (->
    GG.actionCostsController.getCost('chromosomeSelected')
  ).property('currentTown')
  selectFirstParent: ->
    if @get('content.sex') == GG.MALE
      GG.statemanager.send 'selectFatherMeiosis'
    else
      GG.statemanager.send 'selectMotherMeiosis'
  rerender: ->
    @_super()
    setTimeout =>
      @set('useGametes', false)
      GG.meiosisController.set(@get('motherFather') + "View", _this)
    , 200
  _createGametes: ->
    meiosisControl = GG.tasksController.get 'currentTask.meiosisControl'
    doCrossover = if GG.breedingController.get('breedType') == GG.BREED_CONTROLLED and
      (meiosisControl is "crossover" or meiosisControl is "all") then false else true
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
    scale = GG.MeiosisAnimation.get 'timeScale'
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

        leftShift = (if dx > 0 then "+=" else "-=") + Math.abs(dx) + "px"

        animationQueue.push {source: sourceSelector, anim: {left: dx}}

    # temporarily put alleles on top, so we don't see them sliding under other chromosomes
    $(selectorBase + " .allele").css({"z-index": 10})
    for i in [0...animationQueue.length]
      anim = animationQueue[i]
      $(anim.source).animate(anim.anim, GG.MeiosisAnimation.scale(1500), 'easeInOutQuad')

    setTimeout =>
      callback()
      Ember.run.next this, =>
        for i in [0...animationQueue.length]
          anim = animationQueue[i]
          $(anim.source).css({left: '', top: ''})
      # put the alleles back at their default level, so they slide under/over
      $("#" + @get('elementId') + " .allele").css({"z-index": ''})
    , GG.MeiosisAnimation.scale(1550)
  chromosomeSelectedBinding: 'GG.meiosisController.chromosomeSelected'
  crossoverSelectedBinding: 'GG.meiosisController.crossoverSelected'
  doneSelectingCrossoverButtonText: (->
    if @get('crossoverSelected') then "Continue" else "Skip"
  ).property('crossoverSelected')
  doneSelectingChromatidsButtonText: (->
    if @get('chromosomeSelected') then "Continue" else "Skip"
  ).property('chromosomeSelected')
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

GG.MeiosisSpeedSliderView = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  elementId: 'meiosis-speed-slider-parent'
  toolTipText: "Use this slider to speed up or slow down meiosis"
  toolTipConfigTooltip: 'bottomRight'
  toolTipConfigTip: 'bottomRight'
  toolTipConfigTarget: 'topMiddle'
  updateEnabled: (->
    disabled = !GG.powerUpController.hasPowerup("speed control")
    $('#meiosis-speed-slider').slider("option", "disabled", disabled);
  ).observes('GG.powerUpController.powerupChanged', 'GG.tasksController.currentTask')
  didInsertElement: ->
    # slider can go from -Infinity to 1.9999.
    # For now, we'll just have 2 values: 0 and 1.
    # The smaller the slider value, the slower the animation will go.
    $('#meiosis-speed-slider').slider
      orientation: 'horizontal'
      value: (2 - GG.MeiosisAnimation.get('timeScale'))
      min: 0.5
      max: 1.7
      step: 0.01
      change: (event,ui)->
        GG.MeiosisAnimation.set('timeScale', (2 - ui.value))

GG.ObstacleCourseDialogView = Ember.View.extend
  elementId: 'obstacle-course-dialog'
  templateName: 'obstacle-course-dialog'
  tagName: 'div'
  courseBinding: 'GG.obstacleCourseController.course'
  obstaclesBinding: 'GG.obstacleCourseController.obstacles'
  drakeBinding: 'GG.obstacleCourseController.drake'
  taskReputationBinding: 'GG.reputationController.currentTaskReputation'
  extraBreedsRepBinding: 'GG.reputationController.extraBreedsRep'
  meiosisControlRepBinding: 'GG.reputationController.meiosisControlRep'
  alleleRevealRepBinding: 'GG.reputationController.alleleRevealRep'
  visibleBinding: 'GG.obstacleCourseController.dialogVisible'
  taskCompleteBinding: 'GG.obstacleCourseController.taskComplete'
  currentObstacleBinding: 'GG.obstacleCourseController.currentObstacle'
  myTotalTimeBinding: 'GG.obstacleCourseController.myTotalTime'
  opponentTotalTimeBinding: 'GG.obstacleCourseController.opponentTotalTime'
  nTrainingsBinding: 'GG.cyclesController.cycles'
  modeBinding: 'GG.obstacleCourseController.mode'
  trainingPoints: (->
    @get('nTrainings') * GG.actionCostsController.getCost('cycleRemainingBonus')
  ).property('nTrainings')
  courseCompletionPoints: (->
    GG.obstacleCourseController.get('reputationEarned') - @get('trainingPoints')
  ).property('GG.obstacleCourseController.reputationEarned', 'trainingPoints')
  isExternalObstacleCourse: (->
    @get('mode') == GG.OBSTACLE_COURSE_EXTERNAL
  ).property('mode')

  tryAgain: ->
    # restart task
    GG.tasksController.restartCurrentTask()
  continueOn: ->
    # Go back to town
    GG.statemanager.transitionTo 'inTown'

GG.ObstacleTimeView = Ember.View.extend
  tagName: 'div'
  obstacle: null
  breedsLeftBinding: 'GG.cyclesController.cycles'
  time: (->
    time = GG.obstacleCourseController.calculateTime(@get('obstacle'), false)
  ).property('obstacle','breedsLeft')

GG.ObstacleView = Ember.View.extend
  tagName: 'div'
  classNames: ['obstacle']
  classNameBindings: ['type', 'after']
  attributeBindings  : ['style']
  after: false
  skipStyle: false
  style: (->
    if @get 'skipStyle'
      ""
    else
      "top: " + @get('content.positionY') + "px; left: " + @get('content.positionX') + "px;"
  ).property('content.positionY','content.positionX','skipStyle')
  typeBinding: "content.obstacle"

GG.PasswordField = Ember.TextField.extend
  type: "password"
  value: ""
  loginView: null
  keyUp: (evt)->
    @interpretKeyEvents(evt)
    if evt.keyCode == 13 and @get('loginView')?
      @get('loginView').login()

GG.BaselineTaskListView = Ember.View.extend
  tagName: 'div'
  templateName: 'task-list'

  taskSelected: (evt) ->
    GG.statemanager.send 'taskSelected', evt.context

GG.townUnlockView = Ember.View.extend
  templateName: 'town-unlock'
  contentBinding: 'GG.townsController'
  costBinding: 'content.nextTownsCost'
  showPayMessageBinding: 'content.canPayForNextTown'
  firstTown: (->
    @get 'content.firstObject'
  ).property('content.[]')

GG.HelpModeButton = Ember.View.extend GG.PointsToolTip,
  tagName: 'div'
  classNames: ['questionmark-button']
  classNameBindings: ['active']
  activeBinding: 'GG.tooltipController.show'
  forceTooltip: true
  toolTipText: "Click to get help by hovering over objects."
  click: ->
    GG.statemanager.send 'toggleHelpMode'
