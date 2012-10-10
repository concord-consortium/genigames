GG.User = Ember.Object.extend
  login: null
  first: null
  last: null
  class_words: []
  teacher: false
  reputation: 0

  name: (->
    return @get('first') + " " + @get('last')
  ).property('first', 'last')

  # User object gets created *before* we load the learner data,
  # so we have to manually trigger restoring the user state
  restoreState: ->
    prevState = GG.userController.loadState("user", this)
    console.log("restoring user state", prevState)
    for k in Object.keys(prevState)
      @set(k, prevState[k])

  serialize: ->
    {reputation: @get('reputation')}

  triggerSave: (->
    GG.userController.saveState('user', this)
  ).observes('reputation')

GG.Town = Ember.Object.extend
  name: "Town"
  icon: "huts"
  position: 0
  finalMessage: "Nice work, you've completed all the tasks in this town!"
  otherTownsBinding: Ember.Binding.oneWay('GG.townsController.content')
  enabled: (->
    towns = @get('otherTowns')
    idx = towns.indexOf(this)
    if idx is 0
      return true
    for i in [0..(idx-1)]
      return false unless towns[i].get('completed')
    return true
  ).property().volatile()

  tasks: []
  realTasks: []
  completed: false

  init: ->
    @_super()
    tasks = []
    for ts in @get 'tasks'
      task = GG.Task.create ts
      tasks.pushObject task

    @set('realTasks', tasks)

    prevState = GG.userController.loadState("town", this)
    for k in Object.keys(prevState)
      @set(k, prevState[k])

  serialize: ->
    {completed: @get('completed')}

  triggerSave: (->
    GG.userController.saveState('town', this)
  ).observes('completed')

GG.Task = Ember.Object.extend
  visibleGenes: null
  hiddenGenes: null
  initialDrakes: null
  targetDrake: null
  targetCount: 1
  npc: null
  completed: false
  matchCount: 0
  reputation: 1
  cycles: 10
  cyclesRemaining: 0
  # viewmodel properties
  showQuestionBubble: false
  showSpeechBubble: false
  showCompletionBubble: false
  showNonCompletionBubble: false
  showFinalMessageBubble: false

  init: ->
    @_super()
    prevState = GG.userController.loadState("task", this)
    for k in Object.keys(prevState)
      @set(k, prevState[k])

  serialize: ->
    {completed: @get('completed')}

  triggerSave: (->
    GG.userController.saveState('task', this)
  ).observes('completed')

  isComplete: ->
    # parse required characteristics
    parsedCharacteristics = @get('targetDrake').split(/\s*,\s*/).map (ch, idx, arr)->
      ch = ch.toLowerCase()
      ch.charAt(0).toUpperCase() + ch.slice(1)
    drake = GG.breedingController.get 'child'
    if drake.hasCharacteristics(parsedCharacteristics)
      @set 'matchCount', (@get 'matchCount')+1
      return true if @get('matchCount') >= @get('targetCount')
    return false

GG.Drake = Ember.Object.extend
  visibleGenesBinding: 'GG.drakeController.visibleGenes'
  hiddenGenesBinding: 'GG.drakeController.hiddenGenes'
  revealedAlleles: null

  biologicaOrganism : null            # organism object created by GWT
  sex               : null
  imageURL          : null
  bred              : false

  init: ->
    @_super()
    @set 'revealedAlleles', {a: [], b: []}

  genotype: (->
    alleleString = @get('biologicaOrganism').getAlleleString()


    a: alleleString.match(/a:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
    b: alleleString.match(/b:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
  ).property('biologicaOrganism')

  filterGenotype: (genotype, filter) ->
    return {a: GG.Genetics.filter(genotype.a, filter), b: GG.Genetics.filter(genotype.b, filter)}

  visibleGenotype: (->
    if @get('visibleGenes')?
      vis = @filterGenotype @get('genotype'), @get('visibleGenes')
      @get('revealedAlleles').a.forEach( (item, index, enumerable) ->
        vis.a.push(item) if vis.a.indexOf(item) == -1
      )
      @get('revealedAlleles').b.forEach( (item, index, enumerable) ->
        vis.b.push(item) if vis.b.indexOf(item) == -1
      )
      return vis
    else
      return {a: [], b: []}
  ).property('genotype', 'visibleGenes', 'revealedAlleles').volatile()

  hiddenGenotype: (->
    if @get('hiddenGenes')?
      hid = @filterGenotype @get('genotype'), @get('hiddenGenes')
      @get('revealedAlleles').a.forEach( (item, index, enumerable) ->
        hid.a.splice(hid.a.indexOf(item), 1) if hid.a.indexOf(item) != -1
      )
      @get('revealedAlleles').b.forEach( (item, index, enumerable) ->
        hid.b.splice(hid.b.indexOf(item), 1) if hid.b.indexOf(item) != -1
      )
      return hid
    else
      return {a: [], b: []}
  ).property('genotype', 'hiddenGenes', 'revealedAlleles').volatile()

  markRevealed: (side, allele) ->
    rAlleles = @get 'revealedAlleles'
    if rAlleles[side].indexOf(allele) == -1
      rAlleles[side].push(allele)
      @set 'revealedAlleles', rAlleles

  female: (->
    @get('sex') == GG.FEMALE
  ).property('sex')

  male: (->
    @get('sex') == GG.MALE
  ).property('sex')

  hasCharacteristics: (characteristics) ->
    gorg = @get 'biologicaOrganism'

    for ch in characteristics
      has = false
      if ch == "Female"
        has = @get 'female'
      else if ch == "Male"
        has = @get 'male'
      else
        has = ~gorg.getAllCharacteristics().indexOf ch
      return false unless has
    return true

  allelesString: (->
    genotype = @get 'visibleGenotype'
    genotype.a.concat(genotype.b).join(',') unless !genotype
   ).property('visibleGenotype')

# a helper for creating a GG.Drake from a Biologica/GWT organism object
GG.Drake.createFromBiologicaOrganism = (org) ->
  GG.Drake.create
    biologicaOrganism: org
    imageURL         : GG.imageNameStart + org.getImageName()
    sex              : org.sex

GG.LogEvent = Ember.Object.extend
  user        : null
  session     : null
  time        : null
  event       : null
  parameters  : null

# not certain how we want to define our event constants. This will do fine for now
GG.Events =
  # Session events
  STARTED_SESSION : "Started session"

  # Town events
  ENTERED_TOWN    : "Entered town"
  COMPLETED_TOWN  : "Completed town"

  # Task events
  STARTED_TASK    : "Started task"
  COMPLETED_TASK  : "Completed task"
  REPUTATION_CHANGED : "Reputation changed"

  # Breeding events
  SELECTED_PARENT : "Selected parent"
  REMOVED_PARENT  : "Removed parent"
  BRED_DRAGON     : "Bred dragon"
  KEPT_OFFSPRING  : "Kept offspring"
  FREED_OFFSPRING : "Freed offspring"
  SUBMITTED_OFFSPRING : "Submitted offspring"
  REVEALED_ALLELE : "Revealed allele"

GG.TaskNPC = Ember.Object.extend
  name: null
  imageURL: null
  task: null
  position: null

GG.ActionCosts = Ember.Object.extend
  breedButtonClicked: 1
