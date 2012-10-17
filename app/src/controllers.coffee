minispade.require 'genigames/controller-mixins'

GG.townsController = Ember.ArrayController.create
  content    : []
  currentTown: null

  addTown: (town) ->
    @pushObject town

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

  setCurrentTask: (task, force=false) ->
    @completeTasksThrough @indexOf(task) - 1 if force
    return if task is @currentTask

    if @indexOf(task) >= 0
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

  loadTask: (taskIndex) ->
    tasks = @get('content')
    @setCurrentTask(@get('content')[taskIndex], true) if taskIndex < tasks.length


  completeCurrentTask: ->
    task = @get 'currentTask'
    task.set 'completed', true
    GG.userController.addReputation task.get 'reputation'
    GG.logController.logEvent GG.Events.COMPLETED_TASK, name: task.get('name')

  completeTasksThrough: (n) ->
    task.set('completed', true) for task, i in @get('content') when i <= n
    GG.logController.logEvent GG.Events.COMPLETED_TASK, name: ("Tasks through #" + n)

  currentLevelId: (->
    task = @get 'currentTask'
    if task then " - "+ (@indexOf(task) + 1)
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
    task.set 'showQuestionBubble', false
    task.set 'showSpeechBubble', true

  showTaskCompletion: ->
    task = @get 'currentTask'
    task.set 'showQuestionBubble', false
    task.set 'showSpeechBubble', false
    task.set 'showCompletionBubble', true

  showTaskNonCompletion: ->
    task = @get 'currentTask'
    task.set 'showNonCompletionBubble', true

  nonCompletionBubbleDismissed: ->
    @get('currentTask').set 'showNonCompletionBubble', false

  taskAccepted: (task) ->
    task.set 'showSpeechBubble', false
    @setCurrentTask task
    GG.statemanager.transitionTo 'inTask'

  taskFinishedBubbleDismissed: ->
    @get('currentTask').set 'showCompletionBubble', false
    GG.statemanager.transitionTo 'inTown'

  isCurrentTaskComplete: ->
    currentTask = @get 'currentTask'
    return currentTask.isComplete()

GG.drakeController = Ember.Object.create
  visibleGenesBinding: 'GG.tasksController.currentTask.visibleGenes'
  hiddenGenesBinding: 'GG.tasksController.currentTask.hiddenGenes'

GG.parentController = Ember.ArrayController.create
  content: []
  maxMales: 4
  maxFemales: 4
  selectedMother: null
  selectedFather: null

  reset: ->
    @set 'selectedMother', null
    @set 'selectedFather', null
    @set 'content', []

  females: (->
    drake for drake in @get('content') when drake.sex is GG.FEMALE
  ).property('content.@each')

  males: (->
    drake for drake in @get('content') when drake.sex is GG.MALE
  ).property('content.@each')

  selectMother: (drake) ->
    if drake.sex isnt GG.FEMALE then throw "GG.parentController.selectMother: tried to set a non-female as mother"
    @set 'selectedMother', drake
    GG.logController.logEvent GG.Events.SELECTED_PARENT, alleles: drake.get('biologicaOrganism.alleles'), sex: GG.FEMALE

  selectFather: (drake) ->
    if drake.sex isnt GG.MALE then throw "GG.parentController.selectMother: tried to set a non-male as father"
    @set 'selectedFather', drake
    GG.logController.logEvent GG.Events.SELECTED_PARENT, alleles: drake.get('biologicaOrganism.alleles'), sex: GG.MALE

  hasRoom: (drake) ->
    if drake.sex is GG.MALE
      return @get('males').length < @get 'maxMales'
    else
      return @get('females').length < @get 'maxFemales'

GG.fatherPoolController = Ember.ArrayController.create
  contentBinding: 'GG.parentController.males'
  selectedBinding: 'GG.parentController.selectedFather'
  hidden: true
  drakeSelected: (drake) ->
    GG.parentController.selectFather drake

GG.motherPoolController = Ember.ArrayController.create
  contentBinding: 'GG.parentController.females'
  selectedBinding: 'GG.parentController.selectedMother'
  hidden: true
  drakeSelected: (drake) ->
    GG.parentController.selectMother drake

# Fixme: This needs to be rethrought now that we will always only
# have one offspring. Maybe it can just be replaced by breedingController.child
GG.offspringController = Ember.Object.create
  content: null
  hidden: false
  selectedBinding: 'content'


GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  isBreeding: false
  child: null

  breedDrake: ->
    if (@get('mother') && @get('father')) || GG.meiosisController.get('chosenAlleles')?
      GG.statemanager.send 'decrementCycles', 1
      @set 'isBreeding', true
      org = null
      if GG.meiosisController.get('chosenAlleles')?
        org = BioLogica.Organism.createOrganism(GG.DrakeSpecies, GG.meiosisController.get('chosenAlleles'), GG.meiosisController.get('chosenSex'))
      else
        org = BioLogica.breed @get('mother.biologicaOrganism'), @get('father.biologicaOrganism')
      drake = GG.Drake.createFromBiologicaOrganism org
      drake.set 'bred', true
      GG.breedingController.set 'child', drake
      GG.offspringController.set 'content', drake
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
    @set 'cycles', @get('cycles')-amt
  reset: ->
    GG.tasksController.set 'cycles', GG.tasksController.get 'cycles'
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
    pos = num * 35
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
    user.set 'reputation', user.get('reputation') + amt
    GG.logController.logEvent GG.Events.REPUTATION_CHANGED, amount: amt, result: user.get('reputation')

  loadState: (type, obj)->
    allState = @get('state')
    if allState? and allState[type]? and allState[type][obj.get('name')]?
      return allState[type][obj.get('name')]
    else
      return {}

  saveState: (type, obj)->
    # FIXME need to use a lock/free mechanism to avoid race conditions
    allState = @get('state')
    allState = {} unless allState?
    allState[type] = {} unless allState[type]
    allState[type][obj.get('name')] = obj.serialize()
    @set('state', allState)
    if @get('learnerDataUrl')?
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
  userBinding: 'GG.userController.user'
  error: false
  loggingIn: false
  firstTime: true
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
      @set('loggingIn', false)
      if data.error?
        @set('error', true)
      else
        user = GG.User.create data
        @set('user', user)
        GG.statemanager.send 'successfulLogin'
    , "json").error =>
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
    $.getJSON @logoutUrl, (data) ->
      GG.statemanager.transitionTo 'loggingIn'

GG.actionCostsController = Ember.Object.create
  getCost: (action) ->
    @get('content.'+action)

GG.meiosisController = Ember.Object.create
  motherView: null
  fatherView: null
  chosenMotherAllelesBinding: 'motherView.chosenGameteAlleles'
  chosenFatherAllelesBinding: 'fatherView.chosenGameteAlleles'
  chosenSexBinding: 'fatherView.chosenSex'
  chosenAlleles: (->
    return @get('chosenMotherAlleles') + "," + @get('chosenFatherAlleles')
  ).property('chosenMotherAlleles','chosenFatherAlleles')
  animate: (callback)->
    if @get('motherView')? and @get('fatherView')?
      @get('motherView').animate()
      @get('fatherView').animate(callback)
  resetAnimation: ->
    if @get('motherView')? and @get('fatherView')?
      @get('motherView').resetAnimation()
      @get('fatherView').resetAnimation()

