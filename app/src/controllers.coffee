minispade.require 'genigames/controller-mixins'

GG.townsController = Ember.ArrayController.create
  content    : []
  currentTown: null

  addTown: (town) ->
    @pushObject town

  setCurrentTown: (town) ->
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

  completeCurrentTown: ->
    @get('currentTown').set('completed', true)


GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null

  reset: ->
    @set 'content', []
    @set 'currentTask', null

  addTask: (task) ->
    @pushObject task

  setCurrentTask: (task) ->
    return if task is @currentTask
    if @indexOf(task) >= 0
      @set 'currentTask', task
      setTimeout ->
        for femaleAlleles in task.initialDrakes.females
          GenGWT.generateAliveDragonWithAlleleStringAndSex femaleAlleles, 0, (org) ->
            GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

        for maleAlleles in task.initialDrakes.males
          GenGWT.generateAliveDragonWithAlleleStringAndSex maleAlleles, 1, (org) ->
            GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

      , 1000
      GG.logController.logEvent GG.Events.STARTED_TASK, name: task.get('name')
    else
      throw "GG.tasksController.setCurrentTask: argument is not a known task"

  targetCountBinding: Ember.Binding.oneWay('currentTask.targetCount')
  matchCountBinding:  Ember.Binding.oneWay('currentTask.matchCount')

  showTaskDescription: (task) ->
    task.set 'showQuestionBubble', false
    task.set 'showSpeechBubble', true

  showTaskCompletion: (task) ->
    task.set 'showQuestionBubble', false
    task.set 'showSpeechBubble', false
    task.set 'showCompletionBubble', true

  taskAccepted: (task) ->
    task.set 'showSpeechBubble', false
    @setCurrentTask task
    GG.statemanager.transitionTo 'inTask'

  taskCompleted: (task) ->
    task.set 'showCompletionBubble', false
    task.set 'completed', true
    # @setCurrentTask null
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
    GG.logController.logEvent GG.Events.SELECTED_PARENT, alleles: drake.get('biologicaOrganism.alleles'), sex: GG.M

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

GG.offspringController = Ember.ArrayController.create GG.fifoArrayController,
  maxLength: 3
  content: []


GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  isBreeding: false
  child: null

  breedDrake: ->
    if @get('mother') && @get('father')
      GG.statemanager.send 'incrementCounter', GG.actionCostsController.getCost 'breedButtonClicked'
      @set 'isBreeding', true
      GenGWT.breedDragon @get('mother.biologicaOrganism'), @get('father.biologicaOrganism'), (org) =>
        drake = GG.Drake.createFromBiologicaOrganism org
        drake.set 'bred', true
        GG.breedingController.set 'child', drake
        GG.offspringController.pushObject drake
        @set 'isBreeding', false
        GG.statemanager.send 'checkForTaskCompletion'
        GG.logController.logEvent GG.Events.BRED_DRAGON,
          mother: @get('mother.biologicaOrganism.alleles')
          father: @get('father.biologicaOrganism.alleles')
          offspring: drake.get('biologicaOrganism.alleles')

GG.moveController = Ember.Object.create
  moves: 0
  previousMoves: 0
  increment: (amt) ->
    @set 'previousMoves', @get 'moves'
    @set 'moves', @get('previousMoves')+amt
  decrement: (amt) ->
    @set 'previousMoves', @get 'moves'
    @set 'moves', @get('previousMoves')-amt
  reset: ->
    @set 'previousMoves', 0
    @set 'moves', 0
  updateCounter: (->
    moves = @get 'moves'
    hundreds = Math.floor(moves / 100) % 10
    $('#moveCounterHundreds').animate({backgroundPosition: @getPosition(hundreds)}, 200)
    tens = Math.floor(moves / 10) % 10
    $('#moveCounterTens').animate({backgroundPosition: @getPosition(tens)}, 200)
    ones = moves % 10
    $('#moveCounterOnes').animate({backgroundPosition: @getPosition(ones)}, 200)
  ).observes('moves')
  getPosition: (num) ->
    pos = num * 35
    "(0px -" + pos + "px)"

GG.logController = Ember.Object.create
  user: 'test'      # eventually: userBinding: 'GG.userController.content'
  session: null
  eventQueue: []

  startNewSession: ->
    @set('session', @generateGUID())
    @logEvent GG.Events.STARTED_SESSION

  logEvent: (evt, params) ->
    logData =
      user        : @get('user')
      session     : @get('session')
      time        : new Date().getTime()
      event       : evt
      parameters  : params

    # for a quick demo, use window.socket
    socket?.emit 'log', logData

    @eventQueue.push GG.LogEvent.create logData


  generateGUID: ->
    S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()

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
      @set('loaded', true)
    ).error =>
      @set('state', null)
      @set('loaded', true)
  ).observes('learnerId')

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
    $.post @get('learnerDataUrl'), JSON.stringify(allState), (data) =>
      console.log 'state saved'

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
