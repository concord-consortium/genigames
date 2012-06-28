GG.tasksController = Ember.ArrayController.create
  content    : []
  currentTask: null

  addTask: (task) ->
    @pushObject task

  setCurrentTask: (task) ->
    if @indexOf(task) >= 0
      @set 'currentTask', task
      GG.logController.logEvent GG.Events.STARTED_TASK, name: task.get('name')
    else
      throw "GG.tasksController.setCurrentTask: argument is not a known task"


GG.drakeController = Ember.Object.create
  visibleGenesBinding: 'GG.tasksController.currentTask.visibleGenes'


GG.parentController = Ember.ArrayController.create
  content: []
  selectedMother: null
  selectedFather: null

  females: (->
    drake for drake in @get('content') when drake.sex is GG.FEMALE
  ).property('content.@each').cacheable()

  males: (->
    drake for drake in @get('content') when drake.sex is GG.MALE
  ).property('content.@each').cacheable()

  selectMother: (drake) ->
    if drake.sex isnt GG.FEMALE then throw "GG.parentController.selectMother: tried to set a non-female as mother"
    @set 'selectedMother', drake
    GG.logController.logEvent GG.Events.SELECTED_PARENT, alleles: drake.getPath('biologicaOrganism.alleles'), sex: GG.FEMALE

  selectFather: (drake) ->
    if drake.sex isnt GG.MALE then throw "GG.parentController.selectMother: tried to set a non-male as father"
    @set 'selectedFather', drake
    GG.logController.logEvent GG.Events.SELECTED_PARENT, alleles: drake.getPath('biologicaOrganism.alleles'), sex: GG.M


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

GG.offspringController = Ember.ArrayController.create
  content: []


GG.breedingController = Ember.Object.create
  motherBinding: 'GG.parentController.selectedMother'
  fatherBinding: 'GG.parentController.selectedFather'
  isBreeding: false
  child: null

  breedDrake: ->
    if @get('mother') && @get('father')
      @set 'isBreeding', true
      setTimeout =>
        @set 'isBreeding', false
        GG.offspringController.pushObject @get 'child'
      , 1000
      GenGWT.breedDragon @getPath('mother.biologicaOrganism'), @getPath('father.biologicaOrganism'), (org) =>
        drake = GG.Drake.createFromBiologicaOrganism org
        GG.breedingController.set 'child', drake
        GG.logController.logEvent GG.Events.BRED_DRAGON,
          mother: @getPath('mother.biologicaOrganism.alleles')
          father: @getPath('father.biologicaOrganism.alleles')
          offspring: drake.getPath('biologicaOrganism.alleles')


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
    console.log logData

    @eventQueue.push GG.LogEvent.create logData


  generateGUID: ->
    S4 = -> (((1+Math.random())*0x10000)|0).toString(16).substring(1)
    S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4()
