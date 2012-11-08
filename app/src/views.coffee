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


GG.DrakeView = Ember.View.extend
  templateName       : 'drake'
  drakeImage         : (->
    color = @get('org').getCharacteristic 'color'
    if color is "Gray"
      '../images/drakes/greenMetallic-static.png'
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
  maleSpots : (->
    sex = if @get('content.sex') is GG.FEMALE then "female" else "male"
    if sex is "male"
      'drake-male-spots'
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
  classNameBindings: ['defaultClassNames', 'hidden:revealable', 'dominant']
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
  dominant: (->
    ending = @get('displayValue').slice(-1)
    if ending is "1"
      return "dominant"
    else if ending is "2"
      return "recessive"
    else
      return ""
  ).property('displayValue')
  displayValue: (->
    if @get('hidden') then @get('hiddenValue') else GG.drakeController.alleleOverride(@get('value'))
  ).property('value','hidden')
  click: ->
    if @get('hidden')
      GG.userController.addReputation -GG.actionCostsController.getCost 'alleleRevealed'
      if (@get 'drake')? and (@get 'side')?
        @get('drake').markRevealed(@get('side'), @get('value'))
      GG.logController.logEvent GG.Events.REVEALED_ALLELE, allele: @get('value'), side: @get('side'), drake: { alleles: @get('drake.biologicaOrganism.alleles'), sex: @get('drake.sex') }

GG.ChromoView = Ember.View.extend
  templateName: 'chromosome'
  content: null
  chromo: '1'
  side: 'a'
  sister: null
  hiddenGenesBinding: 'GG.drakeController.hiddenGenes'
  visibleGenesBinding: 'GG.drakeController.visibleGenes'
  revealedContentAllelesIdxBinding: 'content.revealedIdx'
  revealedAlleles: null
  gametes: null
  futureGametes: null
  gamete: (->
    return @_getGameteFromGametes('gametes')
  ).property('chromo','side','sister','gametes')
  futureGamete: (->
    return @_getGameteFromGametes('futureGametes')
  ).property('chromo','side','sister','futureGametes')
  _getGameteFromGametes: (prop)->
    if @get(prop)?
      chromo = @get('chromo')
      chromo = if chromo == "X" or chromo == "Y" then "XY" else chromo
      cells = @get(prop).cells
      allX = cells.filter (item)->
        ['x','x1','x2'].contains(item["XY"].side)
      allY = cells.filter (item)->
        item["XY"].side is 'y'
      if @get('side') is 'x1'
        # find the first 2 x sides
        xIdx = if @get('sister') is "1" then 0 else 1
        return allX[xIdx][chromo]
      else if @get('side') is 'x2'
        # find the second 2 x sides
        xIdx = if @get('sister') is "1" then 2 else 3
        return allX[xIdx][chromo]
      else if @get('side') is 'y'
        # find the first 2 y sides
        yIdx = if @get('sister') is "1" then 0 else 1
        return allY[yIdx][chromo]
      else
        sisterIdx = if @get('sister') == "1" then 0 else 1
        if @get('side') is 'b'
          if allY.length > 0
            return allY[sisterIdx][chromo]
          else
            return allX[sisterIdx+2][chromo]
        else
          return allX[sisterIdx][chromo]
    else
      return null
  visibleGamete: (->
    @_filterGamete('gamete',false)
  ).property('gamete', 'visibleGenes')
  hiddenGamete: (->
    @_filterGamete('gamete',true)
  ).property('gamete', 'hiddenGenes')
  futureVisibleGamete: (->
    @_filterGamete('futureGamete',false)
  ).property('futureGamete', 'visibleGenes')
  futureHiddenGamete: (->
    @_filterGamete('futureGamete',true)
  ).property('futureGamete', 'hiddenGenes')
  _filterGamete: (prop, hidden)->
    res = null
    if @get(prop)?.alleles
      gamete = @get(prop)
      genes = if hidden then 'hiddenGenes' else 'visibleGenes'
      res = GG.Genetics.filter(gamete.alleles, @get(genes))
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
  highlightAlleleChanges: false
  highlightAlleleChangesAfter: false
  visibleAlleles: (->
    res = @_getAlleles(false, false)
    if @get 'highlightAlleleChangesAfter'
      @highlightChanges(res,@get('lastVisibleAlleles'))
      @set('lastVisibleAlleles', res)
    return res
  ).property('chromo','content','side','visibleGamete','revealedAlleles','revealedContentAllelesIdx')
  hiddenAlleles: (->
    return @_getAlleles(true, false)
  ).property('chromo','content','side','hiddenGamete','revealedAlleles','revealedContentAllelesIdx')
  alleles: (->
    vis = @get('visibleAlleles').map (item)->
      {allele: item, visible: true}
    hid = @get('hiddenAlleles').map (item)->
      {allele: item, visible: false}

    bioChromo = @get('content.biologicaOrganism').genetics.genotype.chromosomes["1"]["a"]
    alleles = vis.concat(hid)
    alleles = alleles.sort (a,b)=>
      p1 = bioChromo.getAllelesPosition(a.allele)
      p2 = bioChromo.getAllelesPosition(b.allele)
      if p1 > p2 then 1 else -1
    return alleles
  ).property('visibleAlleles','hiddenAlleles')
  futureVisibleAlleles: (->
    res = @_getAlleles(false, true)
    if @get 'highlightAlleleChanges'
      @highlightChanges(@get('visibleAlleles'),res)
      @set('lastVisibleAlleles', res)
    return res
  ).property('chromo','content','side','futureVisibleGamete','revealedAlleles','revealedContentAllelesIdx')
  futureHiddenAlleles: (->
    return @_getAlleles(true, true)
  ).property('chromo','content','side','futureHiddenGamete','revealedAlleles','revealedContentAllelesIdx')
  _getAlleles: (hidden, future)->
    gamete = if hidden then 'hiddenGamete' else 'visibleGamete'
    gamete = ('future ' + gamete).camelize() if future
    res = []
    if (@get 'content')? or (@get gamete)?
      if (@get gamete)?
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
  futureVisibleGameteChanged: (->
    @get 'futureVisibleAlleles'
    setTimeout =>
      @set('gametes', (@get 'futureGametes'))
    , (500 * @get('numberOfHighlights'))
  ).observes('futureVisibleGamete')
  numberOfHighlights: 3
  highlightChanges: (newAlleles, oldAlleles)->
    return if oldAlleles.length == 0
    changes = newAlleles.filter (item) ->
      return !oldAlleles.contains(item)
    setTimeout =>
      # chromo = '.' + @get('chromoName') + '.' + @get('parent') + '.' + @get('right')
      # chromo += '.' + @get('sister') if @get('sister').length > 0
      chromo = '#' + @get('elementId')
      num = @get 'numberOfHighlights'
      for i in [0...changes.length]
        change = GG.drakeController.alleleOverride(changes[i])
        sel = chromo + ' .allele:onlyContains("' + change + '")'
        @_flash(num, sel)
    , 50
  _flash: (n, selector)->
    return if n <= 0
    $(selector).animate({opacity: 0.2},250)
    setTimeout =>
      $(selector).animate({opacity: 1.0},250)
      setTimeout =>
        @_flash(n-1, selector)
      , 250
    , 250
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
  init: ->
    @_super()
    if @get('content')?
      @contentChanged()
  contentChanged: (->
    GG.meiosisController.set(@get('motherFather') + "View", this)
  ).observes('content')
  classNames: ['meiosis']
  classNameBindings: ['motherFather']
  motherFather: (->
    if @get('content.sex') == GG.MALE then "father" else "mother"
  ).property('content')
  gametes: null
  sistersHidden: true
  animate: (callback)->
    GG.MeiosisAnimation.animate(".meiosis." + @get('motherFather'), this, callback)
  resetAnimation: (callback)->
    GG.MeiosisAnimation.reset(".meiosis." + @get('motherFather'), this, callback)
    @set('gametes', null)
  crossOver: ->
    newGametes = @get('content.biologicaOrganism').createGametesWithCrossInfo(4)[0]
    mf = if @get('content.sex') == GG.MALE then "male" else "female"

    # Transfer revealed status to new gametes...
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

    @set 'gametes', newGametes
  randomGameteNumber: (->
    ExtMath.randomInt(4)
  ).property('gametes')
  randomGameteAnimationCell: (->
    # cells are arranged: 0 2
    #                     1 3
    # where 0 and 2 are always first and second female gamete
    # and 1 and 3 are either first and second male gamete or third and fourth female gamete
    num = @get 'randomGameteNumber'
    gametes = @get 'gametes'
    m = 0
    f = 0
    animCell = 0
    gametes.cells.forEach (item, idx)->
      if idx is num
        if ['x','x1','x2'].contains(item.XY.side)
          if f is 0
            animCell = 0
          else if f is 1
            animCell = 2
          else if f is 2
            animCell = 1
          else
            animCell = 3
        else if item.XY.side is 'y'
          if m is 0
            animCell = 1
          else
            animCell = 3
      if ['x','x1','x2'].contains(item.XY.side)
        f++
      else
        m++
    return animCell
  ).property('gametes','randomGameteNumber')
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
    $('.obstacle-course .obstacles').animate({left: "-=1300px"}, 5000, 'linear')
    $('.obstacle-course .background').animate({left: "-=300px"}, 5000, 'linear')
    $('.obstacle-course .drake-container').animate({left: "+=318px"}, 5000, 'linear')
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
