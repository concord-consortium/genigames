minispade.require 'genigames/controller-mixins'

## Static variables ##
GG.BREED_AUTOMATED  = "automated"
GG.BREED_CONTROLLED = "controlled"

GG.townsController = Ember.ArrayController.create
  content    : []
  currentTown: null

  addTown: (town) ->
    @pushObject town

  currentTownIndex: (->
    @indexOf(@get('currentTown'))
  ).property('currentTown')

  firstIncompleteTown: (->
    towns = @get('content')
    for i in [0...(towns.length)]
      t = towns[i]
      return t unless t.get('completed')
  ).property('content')

  setCurrentTown: (town, force=false) ->
    @completeTownsThrough @indexOf(town) - 1 if force
    return false if town is @currentTown or not town.get('enabled')

    if @indexOf(town) >= 0
      @set 'currentTown', town
      GG.tasksController.reset()
      for ts in town.get 'realTasks'
        GG.tasksController.addTask ts
      GG.logController.logEvent GG.Events.ENTERED_TOWN, name: town.get('name')
      return true
    else
      throw "GG.townsController.setCurrentTown: argument is not a known town"

  # loads a town by name or number
  loadTown: (townName) ->
    if (not isNaN parseInt(townName))
      town = @get('content')[townName-1]
    else
      town = (town for town in @get('content') when town.get('name') == townName)[0]

    @setCurrentTown(town, true) if town?

  completeCurrentTown: ->
    town = @get('currentTown')
    town.set('completed', true)
    GG.logController.logEvent GG.Events.COMPLETED_TOWN, name: town.get('name')

  # 'completeTownsThrough 2' will complete towns 0,1,2
  completeTownsThrough: (n) ->
    town.set('completed', true) for town, i in @get('content') when i <= n
    GG.logController.logEvent GG.Events.COMPLETED_TOWN, name: ("Towns through #" + n)

GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null

  reset: ->
    @set 'content', []
    @set 'currentTask', null

  addTask: (task) ->
    @pushObject task

  setCurrentTask: (task) ->
    return if task is @get 'currentTask'

    if @indexOf(task) >= 0
      if GG.baselineController.get 'isBaseline'
        task.set 'cyclesRemaining', 0
      else
        task.set 'cyclesRemaining', task.get 'cycles'
      @set 'currentTask', task

      for femaleAlleles in task.initialDrakes.females
        org = BioLogica.Organism.createLiveOrganism GG.DrakeSpecies, femaleAlleles, BioLogica.FEMALE
        GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

      for maleAlleles in task.initialDrakes.males
        org = BioLogica.Organism.createLiveOrganism GG.DrakeSpecies, maleAlleles, BioLogica.MALE
        GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

      GG.logController.logEvent GG.Events.STARTED_TASK, name: task.get('name')
    else
      throw "GG.tasksController.setCurrentTask: argument is not a known task"

  setNextAvailableTask: (taskIndex) ->
    tasks = @get('content')
    @completeTasksThrough taskIndex - 1 if taskIndex < tasks.length

  clearCurrentTask: ->
    @set 'currentTask', null
    GG.parentController.reset()

  awardTaskReputation: (success) ->
    task = @get 'currentTask'
    isCourse = GG.obstacleCourseController.get 'hasObstacleCourse'
    if isCourse
      reputation = GG.obstacleCourseController.get 'reputationEarned'
    else
      reputation = task.get('reputation')
    event = if (isCourse and !success) then GG.Events.INCOMPLETE_COURSE else GG.Events.COMPLETED_TASK
    GG.reputationController.addReputation(reputation, event)
    GG.reputationController.finalizeReputationForTaskRun()
    GG.reputationController.finalizeReputation()


  completeCurrentTask: ->
    task = @get 'currentTask'
    task.set 'completed', true
    @awardTaskReputation true
    GG.logController.logEvent GG.Events.COMPLETED_TASK,
      name: task.get('name')
      breedCounter: GG.cyclesController.get('cycles')

  restartCurrentTask: ->
    task = @get 'currentTask'
    GG.reputationController.resetCurrent()
    GG.logController.logEvent GG.Events.RESTARTED_TASK, name: task.get('name')
    @clearCurrentTask()
    @setCurrentTask(task)
    GG.statemanager.transitionTo 'parentSelect'

  completeTasksThrough: (n) ->
    task.set('completed', true) for task, i in @get('content') when i <= n
    GG.logController.logEvent GG.Events.COMPLETED_TASK, name: ("Tasks through #" + n)

  currentLevelId: (->
    task = @get('currentTask')
    if task then ": " + task.get 'name'
    else ""
  ).property('currentTask')

  currentTargetTraits: (->
    target = @get 'currentTask.targetDrake'
    if target
      target = target.replace(/, ?/g,"</li><li>")
      new Handlebars.SafeString "<ul><li>" + target + "</li></ul>"
    else ""
  ).property('currentTask')

  targetCountBinding: Ember.Binding.oneWay('currentTask.targetCount')
  matchCountBinding:  Ember.Binding.oneWay('currentTask.matchCount')

  showTaskDescription: (task) ->
    @setCurrentTask task
    otherTask.set('showQuestionBubble', false) for otherTask in GG.tasksController.content
    task.set 'showSpeechBubble', true

  showTaskCompletion: ->
    if GG.baselineController.get('isNotBaseline') and GG.lastShownDialog?
      try
        GG.tutorialMessageController.set('finishButtonTutorialShown', true)
        GG.lastShownDialog.qtip('hide')
      finally
        GG.lastShownDialog = null
    $('#completion-dialog').show()
    $('#modal-backdrop-fade').show()

  showTaskNonCompletion: ->
    msg = "That's not the %@ you're looking for!".fmt(Ember.I18n.t('drake'))
    msg += " You're trying to "
    msg += (
      @get('currentTask.npc.speech.shortText').toLowerCase() ||
      ("breed a drake with " + @get('currentTask.targetDrake') + ".")
    ).replace('drake', Ember.I18n.t('drake'))
    GG.showModalDialog msg

  taskAccepted: (task) ->
    task.set 'showSpeechBubble', false
    GG.statemanager.transitionTo 'inTask'

  taskFinishedBubbleDismissed: ->
    if GG.baselineController.get('isBaseline')
      GG.statemanager.transitionTo 'inTaskList'
    else
      @get('currentTask').set 'showCompletionBubble', false
      if GG.obstacleCourseController.get 'hasObstacleCourse'
        GG.statemanager.transitionTo 'obstacleCourse'
      else
        GG.statemanager.transitionTo 'inTown'

  isCurrentTaskComplete: ->
    task = @get 'currentTask'
    drake = GG.breedingController.get 'child'

    if not task? or not drake?
      return false

    # parse required characteristics
    parsedCharacteristics = task.get('targetDrake').split(/\s*,\s*/).map (ch, idx, arr)->
      ch = ch.toLowerCase()
      ch.charAt(0).toUpperCase() + ch.slice(1)
    if drake.hasCharacteristics(parsedCharacteristics)
      task.set 'matchCount', (task.get 'matchCount')+1
      return true if task.get('matchCount') >= task.get('targetCount')
    return false

  meiosisControlEnabled: (->
    !!@get 'currentTask.meiosisControl'
  ).property('currentTask.meiosisControl')

  hasHiddenGenes: (->
    hidden = @get 'currentTask.hiddenGenes'
    if hidden? and hidden.length > 0
      return true
    else
      return false
  ).property('currentTask.hiddenGenes')

  baselineTaskReputation: (->
    rep = 0
    if @get('currentTask')?
      cyclesUsed = @get('currentTask.cyclesRemaining')
      cyclesAllowed = @get('currentTask.cycles')
      if cyclesUsed < (cyclesAllowed/2)
        rep = 100
      else if cyclesUsed > (cyclesAllowed*2)
        rep = 0
      else
        allowed = (cyclesAllowed*2)-(cyclesAllowed/2)
        used = cyclesUsed - (cyclesAllowed/2)
        remaining = allowed - used
        rep = Math.floor(100*(remaining/allowed))
    return rep
  ).property('currentTask','currentTask.cyclesRemaining')

GG.drakeController = Ember.Object.create
  visibleGenesBinding: 'GG.tasksController.currentTask.visibleGenes'
  hiddenGenesBinding: 'GG.tasksController.currentTask.hiddenGenes'

GG.parentController = Ember.ArrayController.create
  content: []
  maxMales: 40
  maxFemales: 40
  selectedMother: null
  selectedFather: null

  reset: ->
    @set 'selectedMother', null
    @set 'selectedFather', null
    @clear()

  females: (->
    drake for drake in @get('content') when drake.sex is GG.FEMALE
  ).property('content.@each')

  males: (->
    drake for drake in @get('content') when drake.sex is GG.MALE
  ).property('content.@each')

  hasRoom: (drake) ->
    if drake.sex is GG.MALE
      return @get('males').length < @get 'maxMales'
    else
      return @get('females').length < @get 'maxFemales'

  whosSelected: (->
    mother = @get('selectedMother')
    father = @get('selectedFather')
    if mother or father
      return "mother" unless father
      return "father" unless mother
      return "both"
    return "none"
  ).property('selectedMother', 'selectedFather')

GG.fatherPoolController = Ember.ArrayController.create
  contentBinding: 'GG.parentController.males'
  selectedBinding: 'GG.parentController.selectedFather'
  hidden: true

GG.motherPoolController = Ember.ArrayController.create
  contentBinding: 'GG.parentController.females'
  selectedBinding: 'GG.parentController.selectedMother'
  hidden: true

# Fixme: This needs to be rethrought now that we will always only
# have one offspring. Maybe it can just be replaced by breedingController.child
GG.offspringController = Ember.Object.create
  content: null
  hidden: false
  selectedBinding: 'content'


GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  isShowingBreeder: false
  isBreeding: false

  breedType: GG.BREED_AUTOMATED
  toggleBreedType: ->
    if GG.breedingController.get('breedType') is GG.BREED_AUTOMATED
      GG.breedingController.set 'breedType', GG.BREED_CONTROLLED
      GG.logController.logEvent GG.Events.ENABLED_MEIOSIS_CONTROL
    else
      GG.breedingController.set 'breedType', GG.BREED_AUTOMATED
      GG.logController.logEvent GG.Events.DISABLED_MEIOSIS_CONTROL

  child: null
  childSavedToParents: false

  breedDrake: ->
    if (@get('mother') && @get('father')) || GG.meiosisController.get('chosenAlleles')?
      @set 'isBreeding', true
      org = null
      if GG.meiosisController.get('chosenAlleles')?
        org = BioLogica.Organism.createOrganism(GG.DrakeSpecies, GG.meiosisController.get('chosenAlleles'), GG.meiosisController.get('chosenSex'))
      else
        org = BioLogica.breed @get('mother.biologicaOrganism'), @get('father.biologicaOrganism')
      drake = GG.Drake.createFromBiologicaOrganism org
      drake.set 'bred', true
      if GG.meiosisController.get('chosenAlleles')?
        revealed = GG.meiosisController.get('chosenRevealedAlleles')
        for r in [0...revealed.length]
          rev = revealed[r]
          drake.markRevealed(rev.side, rev.allele)
      GG.breedingController.set 'child', drake
      GG.offspringController.set 'content', drake
      Ember.run.next ->
        GG.statemanager.send 'showOffspring'
      @set 'isBreeding', false
      GG.logController.logEvent GG.Events.BRED_DRAGON,
        mother: @get('mother.biologicaOrganism.alleles')
        father: @get('father.biologicaOrganism.alleles')
        offspring: drake.get('biologicaOrganism.alleles')

GG.cyclesController = Ember.Object.create
  cyclesBinding: 'GG.tasksController.currentTask.cyclesRemaining'
  increment: (amt=1) ->
    @set 'cycles', @get('cycles')+amt
  decrement: (amt=1) ->
    cycles = @get 'cycles'
    return if cycles <= 0
    @set 'cycles', cycles-amt
  reset: ->
    setTimeout =>
      @updateCounter()
    , 1000
  updateCounter: (->
    cycles = @get 'cycles'
    return if cycles < 0
    hundreds = Math.floor(cycles / 100) % 10
    $('#moveCounterHundreds').animate({backgroundPosition: @getPosition(hundreds)}, 200)
    tens = Math.floor(cycles / 10) % 10
    $('#moveCounterTens').animate({backgroundPosition: @getPosition(tens)}, 200)
    ones = cycles % 10
    $('#moveCounterOnes').animate({backgroundPosition: @getPosition(ones)}, 200)
  ).observes('cycles')
  getPosition: (num) ->
    pos = num * 26
    "(0px -" + pos + "px)"

GG.userController = Ember.Object.create
  learnerDataUrl: (->
    lid = @get('learnerId')
    if lid?
      '/portal/dataservice/bucket_loggers/learner/' + lid + '/bucket_contents.bundle'
    else
      null
  ).property('learnerId')

  user: null
  state: null
  learnerId: null
  loaded: false
  groupInfoSaved: false
  learnerChanged: (->
    # TODO update learner data
    console.log 'learner changed: ', @get('learnerId')
    @set('loaded', false)
    $.getJSON(@get('learnerDataUrl'), (data) =>
      @set('state', data)
      @get('user').restoreState()
      @set('loaded', true)
    ).error =>
      @set('state', null)
      @set('loaded', true)
  ).observes('learnerId')

  addReputation: (amt) ->
    user = @get 'user'
    return unless user
    user.set 'reputation', user.get('reputation') + amt
    GG.logController.logEvent GG.Events.REPUTATION_CHANGED, amount: amt, result: user.get('reputation')

  loadState: (type, obj)->
    allState = @get('state')
    if allState? and allState[type]? and allState[type][obj.get('_id')]?
      return allState[type][obj.get('_id')]
    else
      return {}

  stateQueue: []
  stateQueueProcessing: false
  saveState: (type, obj)->
    stateQueue = @get('stateQueue')
    stateQueue.push({type: type, obj: obj})
    @processStateQueue() unless @get('stateQueueProcessing')

  processStateQueue: ->
    @set('stateQueueProcessing', true)
    queue = @get('stateQueue')
    allState = @get('state') || {}
    while queue.length > 0
      item = queue.shift()
      type = item.type
      obj = item.obj
      allState[type] ||= {}
      allState[type][obj.get('_id')] = obj.serialize()

    @set('state', allState)
    @set('stateQueueProcessing', false)
    Ember.run.once this, "persistSaveState"

  persistSaveState: ->
    if @get('learnerDataUrl')?
      allState = @get('state') || {}
      $.post @get('learnerDataUrl'), JSON.stringify(allState), (data) =>
        console.log 'state saved'

GG.logController = Ember.Object.create
  learnerIdBinding: 'GG.userController.learnerId'
  learnerLogUrl: (->
    lid = @get('learnerId')
    if lid?
      '/portal/dataservice/bucket_loggers/learner/' + lid + '/bucket_log_items.bundle'
    else
      null
  ).property('learnerId')

  learnerLogUrlChanged: (->
    if @get('learnerLogUrl')?
      @processEventQueue()
  ).observes('learnerLogUrl')

  session: null
  eventQueue: []
  eventQueueInProgress: []

  startNewSession: ->
    @set('session', @generateGUID())
    @logEvent GG.Events.STARTED_SESSION
    @startEventQueuePolling()

  startEventQueuePolling: ->
    setInterval =>
      @processEventQueue() unless @eventQueueInProgress.length > 0
    , 10000

  processEventQueue: ->
    if @get('learnerLogUrl')?
      @eventQueueInProgress = @eventQueue.slice(0)
      @eventQueue = []
      while @eventQueueInProgress.length > 0
        evt = @eventQueueInProgress.shift()
        @persistEvent(evt)

  logEvent: (evt, params) ->
    logData =
      session     : @get('session')
      time        : new Date().getTime()
      event       : evt
      parameters  : params

    # for a quick demo, use window.socket
    # socket?.emit 'log', logData
    @persistEvent logData

  persistEvent: (evt)->
    if @get('learnerLogUrl')?
      $.post(@get('learnerLogUrl'), JSON.stringify(evt), (data)->
        console.log 'log event saved'
      ).error =>
        console.log 'log event save failed!'
        @eventQueue.push evt
    else
      @eventQueue.push evt

  generateGUID: ->
    S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

GG.sessionController = Ember.Object.create
  checkTokenUrl: '/portal/verify_cc_token'
  loginUrl:      '/portal/remote_login'
  logoutUrl:     '/portal/remote_logout'
  userBinding:   'GG.userController.user'
  loadedBinding: 'GG.userController.loaded'
  error: false
  loggingIn: false
  firstTime: true
  preloadingComplete: false
  waitingForPreload: false
  loggedIn: (->
    @get('user') != null
  ).property('user')
  classesWithLearners: (->
    found = []
    classes = @get('user.classes')
    if classes? and classes.length > 0
      for i in [0...(classes.length)]
        cl = classes[i]
        if cl? and cl.learner? and cl.learner > 0
          cl.label = cl.name + " (" + cl.teacher + ")"
          found.push(cl)
    return found
  ).property('user')

  checkCCAuthToken: ->
    $.get(@checkTokenUrl, (data) =>
      if data.error?
        @set('error', true)
        @set('loggingIn', false)
      else
        user = GG.User.create data
        @set('user', user)
        GG.statemanager.send 'successfulLogin'
    , "json").error =>
      @set('loggingIn', false)
      @set('error', true)

  loginPortal: (username, password)->
    @set('firstTime', false)
    $.post(@loginUrl, {login: username, password: password}, (data) =>
      @checkCCAuthToken()
    , "json").error =>
      @set('loggingIn', false)
      @set('error', true)

  logoutPortal: ->
    @set('firstTime', true)
    @set('user', null)
    @set('loaded', false)
    @set('loggingIn', false)
    GG.tasksController.set('content',[])
    GG.townsController.set('content',[])
    $.post @logoutUrl, {}, (data) ->
      GG.statemanager.transitionTo 'loggingIn'

GG.actionCostsController = Ember.Object.create
  getCost: (action) ->
    level = GG.townsController.get('currentTownIndex')
    pts = [].concat @get('content.'+action)
    if level >= pts.length
      level = (pts.length - 1) # the final value is used for all remaining levels
    pts[level] || 0

GG.meiosisController = Ember.Object.create
  motherView: null
  fatherView: null
  motherGameteNumberBinding: 'motherView.randomGameteNumberOverride'
  fatherGameteNumberBinding: 'fatherView.randomGameteNumberOverride'
  chosenMotherAllelesBinding: 'motherView.chosenGameteAlleles'
  chosenFatherAllelesBinding: 'fatherView.chosenGameteAlleles'
  chosenMotherGameteBinding: 'motherView.chosenGamete'
  chosenFatherGameteBinding: 'fatherView.chosenGamete'
  chosenSexBinding: 'fatherView.chosenSex'
  chosenAlleles: (->
    return @get('chosenMotherAlleles') + "," + @get('chosenFatherAlleles')
  ).property('chosenMotherAlleles','chosenFatherAlleles')
  chosenRevealedAlleles: (->
    femGam = @get 'chosenMotherGamete'
    maleGam = @get 'chosenFatherGamete'

    res = []
    for own ch of maleGam
      rev = maleGam[ch].revealed || []
      for i in [0...rev.length]
        res.push {allele: rev[i], side: 'b'}
    for own ch of femGam
      rev = femGam[ch].revealed || []
      for i in [0...rev.length]
        res.push {allele: rev[i], side: 'a'}
    return res
  ).property('chosenMotherGamete','chosenFatherGamete')
  animate: (callback)->
    if @get('motherView')? and @get('fatherView')?
      @get('fatherView').animate =>
        GG.tutorialMessageController.showMeiosisMotherTutorial =>
          @get('motherView').animate =>
            GG.MeiosisAnimation.mergeChosenGametes("#" + @get('fatherView.elementId'), "#" + @get('motherView.elementId'), callback)
  resetAnimation: ->
    if @get('motherView')? and @get('fatherView')?
      @get('motherView').resetAnimation()
      @get('fatherView').resetAnimation()
      @set('selectedChromosomes', { father: {}, mother: {}})
      @set('chromosomeSelected', false)
      @set('crossoverSelected', false)
  chromosomeSelected: false
  selectedChromosomes: { father: {}, mother: {}}
  deselectChromosome: (chromoView) ->
    selected = @get('selectedChromosomes')
    source = if chromoView.get('content.sex') == GG.MALE then "father" else "mother"
    chromo = chromoView.get('chromo')
    chromo = "XY" if chromo is "X" or chromo is "Y"
    chromoView.set('selected', false)
    selected[source][chromo] = null

    # Refund the reputation that was charged to select this chromosome
    GG.reputationController.addReputation(GG.actionCostsController.getCost('chromosomeSelected'), GG.Events.CHOSE_CHROMOSOME)

    clearNum = true
    for own chrom,view of selected[source]
      clearNum = false if view?

    if clearNum
      gameteNumberProp = if source is "father" then 'fatherGameteNumber' else 'motherGameteNumber'
      @set(gameteNumberProp, -1)

    # TODO We should probably revert any cell num swaps that happened on selection, so the user can't
    # cheat by selecting and then deselecting and having them move to the same gamete anyway

  selectChromosome: (chromoView) ->
    @set('chromosomeSelected', true)
    selected = @get('selectedChromosomes')
    source = if chromoView.get('content.sex') == GG.MALE then "father" else "mother"
    chromo = chromoView.get('chromo')
    chromo = "XY" if chromo is "X" or chromo is "Y"
    if selected[source][chromo]?
      selected[source][chromo].set('selected', false)
    else
      # There was no previously selected chromosome, so charge rep points
      GG.reputationController.subtractReputation(GG.actionCostsController.getCost('chromosomeSelected'), GG.Events.CHOSE_CHROMOSOME)
    selected[source][chromo] = chromoView
    gameteNumberProp = if source is "father" then 'fatherGameteNumber' else 'motherGameteNumber'
    destGameteNum = @get(gameteNumberProp)
    sourceGameteNum = chromoView.get('cellNum')
    if destGameteNum == -1
      @set(gameteNumberProp, sourceGameteNum)
    else
      # if the selected chromosome is *not* in the to-be-selected gamete, move it into it
      if sourceGameteNum != destGameteNum
        Ember.run =>
          # get the gametes
          gametes = if source is "father" then @get('fatherView.gametes') else @get('motherView.gametes')
          # swap the source chromo and the destination chromo
          destChromo = gametes.cells[destGameteNum][chromo]
          gametes.cells[destGameteNum][chromo] = gametes.cells[sourceGameteNum][chromo]
          gametes.cells[sourceGameteNum][chromo] = destChromo
          # swap the endCellInfo numbers
          destRealSide = ''
          sourceRealSide = ''
          for own side,num of gametes.endCellInfo[chromo]
            sourceRealSide = side if num == sourceGameteNum
            destRealSide = side if num == destGameteNum
          gametes.endCellInfo[chromo][sourceRealSide] = destGameteNum
          gametes.endCellInfo[chromo][destRealSide] = sourceGameteNum
          if source is "father"
            @set('fatherView.gametes', $.extend(true, {}, gametes))
            @get('fatherView').notifyPropertyChange('gametes')
          else
            @set('motherView.gametes', $.extend(true, {}, gametes))
            @get('motherView').notifyPropertyChange('gametes')
  visibility: (chromoView, allele)->
    if chromoView.get('visibleAlleles').indexOf(allele) != -1
      return 'visible'
    if chromoView.get('hiddenAlleles').indexOf(allele) != -1
      return 'hidden'
    else
      return 'invisible'
  crossoverSelected: false
  selectedCrossover: null
  selectCrossover: (destCross)->
    @set('crossoverSelected', true)
    # get the gene for this allele
    gene = BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, destCross.allele)
    destCross.gene = gene
    source = if destCross.chromoView.get('content.sex') == GG.MALE then "father" else "mother"
    meiosisView = @get(source + 'View')
    parentSelector = '#' + meiosisView.get('elementId')

    # Highlight the valid second choices, by removing 'clickable' on invalid ones
    leftRight = destCross.chromoView.get('right')
    points = parentSelector + ' .crossoverPoint:not(.' + gene.name + ')'
    points2 = parentSelector + ' .' + leftRight + ' .crossoverPoint.' + gene.name
    $(points).removeClass('clickable').addClass('hidden')
    $(points2).removeClass('clickable').addClass('hidden')
    # mark this one as selected
    $('#' + destCross.chromoView.get('elementId') + ' .crossoverPoint.' + gene.name).removeClass('hidden').addClass('selected')
    if $(parentSelector + " .crossoverSelection .step3").hasClass('hidden')
      $(parentSelector + " .crossoverSelection .step1").addClass('hidden')
      $(parentSelector + " .crossoverSelection .step2").removeClass('hidden')

    if @get('selectedCrossover')?
      sourceCross = @get('selectedCrossover')
      if sourceCross.gene.name == destCross.gene.name and sourceCross.chromoView.get('side') != destCross.chromoView.get('side')
        GG.reputationController.subtractReputation(GG.actionCostsController.getCost('crossoverMade'), GG.Events.MADE_CROSSOVER)
        # cross these two
        $('#' + destCross.chromoView.get('elementId') + ' .crossoverPoint.' + gene.name).removeClass('clickable').addClass('selected')
        # get all genes after this one
        genesToSwap = [gene]
        allelesToSwap = [
          {
            gene: sourceCross.gene,
            source: sourceCross.allele,
            sourceVisibility: @visibility(sourceCross.chromoView, sourceCross.allele)
            dest: destCross.allele
            destVisibility: @visibility(destCross.chromoView, destCross.allele)
          }
        ]
        for allele in sourceCross.chromoView.get('alleles')
          alGene = BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, allele.allele)
          if alGene.start > sourceCross.gene.start
            genesToSwap.push(alGene)
            allelesToSwap.push
              gene: alGene
              source: allele.allele
              sourceVisibility: @visibility(sourceCross.chromoView, allele.allele)

        for allele in destCross.chromoView.get('alleles')
          alGene = BioLogica.Genetics.getGeneOfAllele(GG.DrakeSpecies, allele.allele)
          if alGene.start > sourceCross.gene.start
            allelesToSwap.map (item)=>
              if item.gene.name == alGene.name
                item.dest = allele.allele
                item.destVisibility = @visibility(destCross.chromoView, allele.allele)
              return item

        GG.logController.logEvent GG.Events.MADE_CROSSOVER,
          sourceChromo:
            drake: if sourceCross.chromoView.get('content.female') then "mother" else "father"
            side: sourceCross.chromoView.get('side')
            chromo: sourceCross.chromoView.get('chromo')
            sister: sourceCross.chromoView.get('sister')
          destinationChromo:
            drake: if destCross.chromoView.get('content.female') then "mother" else "father"
            side: destCross.chromoView.get('side')
            chromo: destCross.chromoView.get('chromo')
            sister: destCross.chromoView.get('sister')
          allelesToSwap: allelesToSwap

        # swap them visually
        sourceCell = sourceCross.chromoView.get('cellNum')
        destCell = destCross.chromoView.get('cellNum')
        moves = {}
        for swapGene in genesToSwap
          moves[swapGene.name] ?= {}
          moves[swapGene.name][sourceCell] = destCell
          moves[swapGene.name][destCell] = sourceCell

        meiosisView.animateMoves moves, =>
          # swap them in the gametes.cells
          gametes = meiosisView.get('gametes')
          chromo = sourceCross.chromoView.get('chromo')

          for swapAlleles in allelesToSwap
            alleles = gametes.cells[sourceCell][chromo].alleles.without(swapAlleles.source)
            alleles.push(swapAlleles.dest)
            gametes.cells[sourceCell][chromo].alleles = alleles

            alleles = gametes.cells[destCell][chromo].alleles.without(swapAlleles.dest)
            alleles.push(swapAlleles.source)
            gametes.cells[destCell][chromo].alleles = alleles

          meiosisView.set('gametes', $.extend(true, {}, gametes))
          meiosisView.notifyPropertyChange('gametes')

          # update the step-by-step directions
          if $(parentSelector + " .crossoverSelection .step3").hasClass('hidden')
            $(parentSelector + " .crossoverSelection .step2").addClass('hidden')
            $(parentSelector + " .crossoverSelection .step3").removeClass('hidden')

          @clearCrossPoints(meiosisView)
      else if sourceCross.chromoView == destCross.chromoView
        # deselect this cross point
        @clearCrossPoints(meiosisView)
        if $(parentSelector + " .crossoverSelection .step3").hasClass('hidden')
          $(parentSelector + " .crossoverSelection .step2").addClass('hidden')
          $(parentSelector + " .crossoverSelection .step1").removeClass('hidden')
      else
        console.log("invalid second cross point!")
    else
      @set('selectedCrossover', destCross)

  clearCrossPoints: (meiosisView)->
    # clear the saved cross point
    @set('selectedCrossover', null)
    Ember.run.next ->
      parentSelector = '#' + meiosisView.get('elementId')
      selector = parentSelector + ' .crossoverPoint'
      $(selector).addClass('clickable')
      $(selector).removeClass('hidden')
      $(selector).removeClass('selected')

GG.obstacleCourseController = Ember.Object.create
  courseBinding: 'GG.tasksController.currentTask.obstacleCourse'
  obstaclesBinding: 'course.obstacles'
  drakeBinding: 'GG.offspringController.content'
  breedsLeftBinding: 'GG.cyclesController.cycles'
  taskComplete: (->
    GG.tasksController.isCurrentTaskComplete()
  ).property('drake')
  obstaclesPassed: 0
  dialogVisible: false
  currentObstacleIndex: 0
  currentObstacle: null

  hasObstacleCourse: (->
    @get('course')? && GG.baselineController.get('isNotBaseline')
  ).property('course')

  setFirstObstacle: (->
    @set 'currentObstacle', @get('obstacles')?[0]
  ).observes 'obstacles'

  setCurrentObstacle: (->
    index = @get 'currentObstacleIndex'
    @set 'currentObstacle', @get('obstacles')?[index]
  ).observes 'currentObstacleIndex'

  goToNextObstacle: ->
    nextIndex = @get('currentObstacleIndex')+1
    @set 'currentObstacleIndex', nextIndex

  showInfoDialog: ->
    if not GG.tasksController.isCurrentTaskComplete()
      text = "Uh oh, you're out of breeds! You're going to have to send this Drake to
              the obstacle course. Good luck!"
    else
      breedsLeft = @get 'breedsLeft'
      num = "no, one, two, three, four, five, six, seven, eight, nine, ten".split(", ")[breedsLeft]
      s = if breedsLeft is 1 then "" else "s"
      text = "Great job, I think this Drake will do well in the obstacle course!
              Because you had #{num} breed#{s} remaining, your Drake "
      text +=
        if breedsLeft then "will be trained #{num} time#{s} before the course,
                            which will make it even faster!"
        else "won't be trained before the course."
    GG.showModalDialog text, -> GG.statemanager.send  "startCourse"

  reputationEarned: (->
    return 0 unless @get('course')?
    taskRep = GG.tasksController.get 'currentTask.reputation'
    if not taskRep? then return null
    taskComplete = @get 'taskComplete'
    if taskComplete
      training = @get 'breedsLeft'
      # earn 10 points per breed left
      return taskRep + (training * 10)
    else
      # earn 10% of repuation per obstacle passed
      # this calculation is ugly...
      @set 'obstaclesPassed', 0
      for obstacle in @get('obstacles')
        @calculateTime(obstacle, false)
      passed = @get 'obstaclesPassed'
      return Math.round  taskRep * passed * 0.1
  ).property('drake', 'obstaclesPassed')

  myTotalTime: (->
    return 0 unless @get('course')? and @get('obstacles')?
    total = 0
    for obstacle in @get('obstacles')
      total += @calculateTime(obstacle, false)
    return total
  ).property('course','breedsLeft','obstacles', 'drake')

  opponentTotalTime: (->
    return 0 unless @get('course')? and @get('obstacles')?
    total = 0
    for obstacle in @get('obstacles')
      total += @calculateTime(obstacle, true)
    return Math.round total
  ).property('course','opponentBreedsLeft','obstacles')

  didPassObstacle: (obstacle=@get('currentObstacle')) ->
    drake  = @get 'drake'
    target = obstacle.target
    parsedCharacteristics = target.split(/\s*,\s*/).map (ch, idx, arr)->
      ch = ch.toLowerCase()
      ch.charAt(0).toUpperCase() + ch.slice(1)
    drake.hasCharacteristics(parsedCharacteristics)

  calculateTime: (obstacle, opponent=false)->
    obsTime = obstacle.time || 1

    # opponent always goes 10% slower
    if opponent then return obsTime * 1.1

    drake  = @get 'drake'
    target = obstacle.target

    return 0 unless drake
    return 1 unless target

    unless @didPassObstacle obstacle
      # failure
      return obsTime * 4

    @set 'obstaclesPassed', @get('obstaclesPassed') + 1
    training = @get 'breedsLeft'
    speedup  = Math.pow(0.9, training)    # reduce speed by 10% for each training cycle

    return Math.round obsTime * speedup

GG.baselineController = Ember.Object.create
  isBaseline: false
  isNotBaseline: Ember.computed.not('isBaseline')

GG.tutorialMessageController = Ember.Object.create
  isFirstTask: (->
    townId = GG.townsController.get("content").indexOf GG.townsController.get "currentTown"
    taskId = GG.tasksController.get("content").indexOf GG.tasksController.get "currentTask"
    return townId+taskId is 0
  ).property('GG.townsController.currentTown', 'GG.tasksController.currentTask')

  isFirstMeiosisDescriptionTask: (->
    townId = GG.townsController.get("content").indexOf GG.townsController.get "currentTown"
    taskId = GG.tasksController.get("content").indexOf GG.tasksController.get "currentTask"
    return townId is 0 and taskId is 2
  ).property('GG.townsController.currentTown', 'GG.tasksController.currentTask')

  # TODO There should be a better way to detect this other than hard-coding it...
  isFirstMeiosisControlTask: (->
    townId = GG.townsController.get("content").indexOf GG.townsController.get "currentTown"
    taskId = GG.tasksController.get("content").indexOf GG.tasksController.get "currentTask"
    return (townId is 0 and taskId is 4) or (GG.baselineController.get('isBaseline') and townId is 1 and taskId is 0)
  ).property('GG.townsController.currentTown', 'GG.tasksController.currentTask')

  showTargetTutorial: ->
    if @get 'isFirstTask' then GG.showInfoDialog $('#target-tutorial-target'),
      "These are the traits of the %@1 you need to create. To do that you have
      to get a male and female parent who can breed the target %@1.".fmt(Ember.I18n.t('drake')),
      target: "leftMiddle"
      tooltip: "rightMiddle"
      hideAction: =>
        @showParentsTutorial()

  firstDrakeSelected: false
  showFirstDrakeSelectionTutorial: (parent) ->
    if @get('isFirstTask') and !@get 'firstDrakeSelected'
      target = if parent is "mother" then "topMiddle" else "bottomMiddle"
      tooltip = if parent is "mother" then "bottomMiddle" else "topMiddle"
      @set 'firstDrakeSelected', true
      GG.showInfoDialog $("##{parent}-chromosome"),
        'This is the %@1 genetic make-up. The alleles <span style="position: relative;">
        <img src="../images/allele-bg.png" style="position: absolute; top: -6px; left: 1px">
        <span style="position: absolute; top: 0; left: 4px; font-weight: bold;" class="dominant">
        W1</span></span><br/>of genes determine the look of the
        %@1, so to get the %@1 you want, you’re going to have to breed to create a
        genetic combination that will produce the %@1.'.fmt(Ember.I18n.t('drake')),
        target: target
        tooltip: tooltip

  firstOffspringCreated: false
  showFirstOffspringCreatedTutorial: ->
    if @get('isFirstTask') and !@get 'firstOffspringCreated'
      @set 'firstOffspringCreated', true
      GG.showInfoDialog $("#offspring-pool .chromosome-panel"),
        "Good job. Notice which alleles of the wing gene gave this %@1 wings.".fmt(Ember.I18n.t('drake')),
        target: "bottomMiddle"
        tooltip: "topMiddle"
        hideAction: =>
          @showFinishButtonTutorial()

  parentsTutorialShown: false
  showParentsTutorial: ->
    if @get('isFirstTask') and !@get 'parentsTutorialShown'
      @set 'parentsTutorialShown', true
      GG.showInfoDialog $("#parents-tutorial-target"),
        "Here is where the parents are kept. The male %@1s have beards; the females do not.
        You need to have one male and one female %@1 to make an offspring.".fmt(Ember.I18n.t('drake')),
        target: "rightMiddle"
        tooltip: "leftMiddle"

  breedButtonTutorialShown: false
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  bothParentsSelected: (->
    @get('mother')? and @get('father')?
  ).property('mother','father')
  showBreedButtonTutorial: ->
    if @get('isFirstTask') and !@get('breedButtonTutorialShown') and @get 'bothParentsSelected'
      @set 'breedButtonTutorialShown', true
      GG.showInfoDialog $("#breed-button"),
        "Now that you’ve picked parents, hit the Breed button to create the child.",
        target: "leftMiddle"
        tooltip: "rightMiddle"

  meiosisTutorialShown:  false
  meiosisTutorial2Shown: false
  showMeiosisTutorial: (callback)->
    if @get('isFirstTask') and !@get('meiosisTutorialShown')
      @set 'meiosisTutorialShown', true
      GG.showInfoDialog $("#meiosis-container .meiosis.father"),
        "This is meiosis, the method by which half of a parent’s alleles are passed to the child.
        You will see each parent's chromosomes getting sorted into four cells. One of the four
        from each parent is randomly chosen for the offspring.",
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else if @get('isFirstMeiosisDescriptionTask') and !@get('meiosisTutorial2Shown')
      @set 'meiosisTutorial2Shown', true
      GG.showChainedInfoDialog $("#meiosis-container .meiosis.father"),
        [
          "When you click the “breed” button, what you’re seeing is the process
          of <b>meiosis</b> and <b>fertilization</b>.",
          "Meiosis produces four <b> gamete</b> cells. Each gamete gets one
          chromosome from each pair of chromosomes.",
          "First, the chromosomes are duplicated. <b>Crossovers</b> can occur at this time."
        ]
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else
      callback()

  meiosisCrossoverTutorialshown: false
  showMeiosisDivisionTutorial: (callback) ->
    if @get('isFirstMeiosisDescriptionTask') and !@get('meiosisCrossoverTutorialshown')
      @set 'meiosisCrossoverTutorialshown', true
      GG.showInfoDialog $("#meiosis-container .meiosis.father"),
        "Then the cell divides twice.",
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else
      callback()

  meiosisFatherGameteTutorialShown: false
  meiosisMotherGameteTutorialShown: false
  showMeiosisGameteTutorial: (callback, parent) ->
    parentTutorialShown = if parent is "mother"
      'meiosisMotherGameteTutorialShown'
    else 'meiosisFatherGameteTutorialShown'
    if @get('isFirstMeiosisDescriptionTask') and !@get parentTutorialShown
      @set parentTutorialShown, true
      text = if parent is "father"
        "The result is four gamete cells with half the normal number of chromosomes.
        In males, gametes are called sperm cells."
      else "In females, gametes are called egg cells."

      GG.showInfoDialog $("#meiosis-container .meiosis.#{parent}"),
        text,
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else
      callback()

  meiosisMotherTutorialShown: false
  showMeiosisMotherTutorial: (callback) ->
    if @get('isFirstMeiosisDescriptionTask') and !@get('meiosisMotherTutorialShown')
      @set 'meiosisMotherTutorialShown', true
      GG.showInfoDialog $("#meiosis-container .meiosis.mother"),
        "The same process happens for the mother.",
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else
      callback()

  meiosisFertilizationTutorialShown: false
  showMeiosisFertilizationTutorial: (callback) ->
    if @get('isFirstMeiosisDescriptionTask') and !@get('meiosisFertilizationTutorialShown')
      @set 'meiosisFertilizationTutorialShown', true
      GG.showInfoDialog $("#meiosis-container"),
        "Fertilization is when a sperm and egg cell fuse. The single chromosomes
        from the male and female parents are now in one cell, resulting in pairs
        of chromosomes. The fertilized egg then divides many times and develops
        into an individual."
        target: "leftMiddle"
        tooltip: "rightMiddle"
        maxWidth: 280
        hideAction: callback
        modal: true
    else
      callback()

  meiosisControlTutorialShown: false
  showMeiosisControlTutorial: ->
    if @get('isFirstMeiosisControlTask') and !@get('meiosisControlTutorialShown') and @get 'bothParentsSelected'
      @set 'meiosisControlTutorialShown', true
      GG.showInfoDialog $("#meiosis-button"),
        "Meiosis control is now active! Turn on this control to choose the chromosomes carrying
        the alleles you need. Then click breed to start."
        target: "leftMiddle"
        tooltip: "rightMiddle"

  finishButtonTutorialShown: false
  showFinishButtonTutorial: ->
    if @get('isFirstTask') and !@get('finishButtonTutorialShown')
      @set 'finishButtonTutorialShown', true
      GG.showInfoDialog $("#offspring-buttons .offspring-buttons-use"),
        "When you have a %@1 that matches the task, hit Finish to end breeding and complete the challenge.".fmt(Ember.I18n.t('drake'))
        target: "leftMiddle"
        tooltip: "rightMiddle"

GG.QTipStyle =
  width:
    max: 350
  padding: '14px',
  border:
    width: 1
    radius: 5
    color: '#4e8da6'
  name: 'light'

GG.lastShownDialog = null
GG.showInfoDialog = ($elem, text, opts={}) ->
  opts.target ?= "leftMiddle"
  opts.tooltip ?= "rightMiddle"
  opts.maxWidth ?= 350
  opts.modal ?= false
  opts.modalFade ?= false

  style = Ember.copy GG.QTipStyle, true
  style.tip = opts.tooltip
  style.width =
    max: opts.maxWidth
  config =
    content:
        title:
          text: '',
          button: 'OK'
        text: text
    position:
      corner:
        target: opts.target
        tooltip: opts.tooltip
    show:
        ready: true
        solo: true
        when: false
    hide: false
    style: style
  if opts.hideAction?
    config.api =
      onHide: opts.hideAction
  if opts.modal
    backdrop = if opts.modalFade then "#modal-backdrop-fade" else "#modal-backdrop-clear"
    config.api ?= {}
    config.api.beforeShow = ->
      $(backdrop).fadeIn(@options.show.effect.length)
    config.api.beforeHide = ->
      $(backdrop).fadeOut(@options.show.effect.length)
  GG.lastShownDialog = $elem
  $elem.qtip config

GG.showChainedInfoDialog = ($elem, textArr, opts={}) ->
  opts.finalCallback = opts.hideAction unless opts.finalCallback?
  text = textArr[0]
  textArr = textArr.splice(1)
  if textArr.length
    opts.hideAction = ->
      GG.showChainedInfoDialog $elem, textArr, opts
    GG.showInfoDialog $elem, text, opts
  else
    opts.hideAction = opts.finalCallback
    GG.showInfoDialog $elem, text, opts

GG.showModalDialog = (text, hideAction) ->
  body = $('body')
  GG.lastShownDialog = body
  body.qtip
    content:
        title:
          text: '',
          button: 'OK'
        text: text
    position:
       target: $(document.body)
       corner: 'center'
    show:
        ready: true
        solo: true
        when: false
    hide: false
    style: GG.QTipStyle
    api:
       onHide: hideAction
       beforeShow: ->
         $('#modal-backdrop-fade').fadeIn(@options.show.effect.length)
       beforeHide: ->
         $('#modal-backdrop-fade').fadeOut(@options.show.effect.length)

GG.reputationController = Ember.Object.create
  reset: (->
    @set('bestTaskReputation', Number.NEGATIVE_INFINITY)
    @set('bestTaskReputationReasons', {})
    @resetCurrent()
  )

  resetCurrent: ->
    @set('currentTaskReputation', 0)
    @set('currentTaskReputationReasons', {})

  bestTaskReputationBinding: 'GG.tasksController.currentTask.reputationEarned'
  bestTaskReputationReasons: {}
  bestTaskReputationDisplay: (->
    best = @get('bestTaskReputation')
    if best < 0 then 0 else best
    ).property('bestTaskReputation')

  currentTaskReputation: 0
  currentTaskReputationReasons: {}

  addReputation: (rep, reason)->
    reasons = @get 'currentTaskReputationReasons'
    current_rep = @get 'currentTaskReputation'

    reasons[reason] ||= 0
    reasons[reason] += rep

    current_rep += rep

    @set('currentTaskReputationReasons', reasons)
    @set('currentTaskReputation', current_rep)

  subtractReputation: (rep, reason)->
    @addReputation(-rep, reason)

  # ensure "current" rep for task is valid
  finalizeReputationForTaskRun: ->
    current = @get 'currentTaskReputation'
    @set 'currentTaskReputation', Math.max current, 0

  # the task is complete
  finalizeReputation: ->
    best = @get 'bestTaskReputation'
    if GG.baselineController.get 'isBaseline'
      # calculate "reputation" based on breeds used
      current = GG.tasksController.get 'baselineTaskReputation'
    else
      current = @get 'currentTaskReputation'

    if current > best
      @set('bestTaskReputation', current)
      @set('bestTaskReputationReasons', @get('currentTaskReputationReasons'))

      best = 0 if best == Number.NEGATIVE_INFINITY
      GG.userController.addReputation(current - best)

  _repFor: (evt)->
    reasons = @get('currentTaskReputationReasons')
    reasons[evt] || 0

  currentTaskBinding: 'GG.tasksController.currentTask'
  reputationForTask: (->
    @get 'currentTask.reputation'
  ).property('currentTask')

  currentTaskReputationAssumingCompletion: (->
    current = @get('currentTaskReputation')
    current += @get('reputationForTask')
    current -= @_repFor GG.Events.INCOMPLETE_COURSE
    current -= @_repFor GG.Events.COMPLETED_TASK
    if current < 0 then 0 else current
  ).property('currentTaskReputation','reputationForTask')

  extraBreedsRep: (->
    @_repFor GG.Events.BRED_WITH_EXTRA_CYCLE
  ).property('currentTaskReputation')

  meiosisControlRep: (->
    enables = @_repFor GG.Events.ENABLED_MEIOSIS_CONTROL
    chromos = @_repFor GG.Events.CHOSE_CHROMOSOME
    crosses = @_repFor GG.Events.MADE_CROSSOVER
    enables + chromos + crosses
  ).property('currentTaskReputation')

  alleleRevealRep: (->
    @_repFor GG.Events.REVEALED_ALLELE
  ).property('currentTaskReputation')

GG.groupsController = Ember.Object.create
  groups: Ember.ArrayProxy.create
    content: Ember.A([
      GG.GroupMember.create(),
      GG.GroupMember.create()
    ])
  error: false
  verifyContent: ->
    groups = @get('groups')
    found = groups.find (user)->
      user.get('invalidName') or user.get('invalidSchoolID')
    if found or groups.get('length') < 1
      @set('error', true)
      return
    @set('error', false)
  removeUser: (user)->
    console.log("remove user called: ", user)
    groups = @get('groups')
    groups.removeObject(user)
    console.log("remove user ended")
  addUser: ->
    console.log("add user called")
    groups = @get('groups')
    groups.pushObject(GG.GroupMember.create())
    console.log("add user ended")

