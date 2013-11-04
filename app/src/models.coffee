GG.User = Ember.Object.extend
  login: null
  first: null
  last: null
  class_words: []
  cohorts: []
  teacher: false
  group: false
  reputation: 0
  skipSave: false

  _idBinding: 'login'
  name: (->
    return @get('first') + " " + @get('last')
  ).property('first', 'last')

  hasCohort: (cohort)->
    @get('cohorts').indexOf(cohort) != -1

  # User object gets created *before* we load the learner data,
  # so we have to manually trigger restoring the user state
  restoreState: ->
    prevState = GG.userController.loadState("user", this)
    console.log("restoring user state", prevState)
    @set 'skipSave', true
    for k in Object.keys(prevState)
      @set(k, prevState[k])
    @set 'skipSave', false

  serialize: ->
    {reputation: @get('reputation')}

  triggerSave: (->
    GG.userController.saveState('user', this) unless @get 'skipSave'
  ).observes('reputation')

GG.Town = Ember.Object.extend
  _id: null
  name: "Town"
  icon: "huts"
  background: "castle"
  position: 0
  finalMessage: "Nice work, you've completed all the tasks in this town!"
  otherTownsBinding: Ember.Binding.oneWay('GG.townsController.content')
  enabled: false

  tasks: []
  realTasks: []
  completed: false
  skipSave: false

  init: ->
    @_super()
    tasks = []
    for ts in @get 'tasks'
      task = GG.Task.create ts
      tasks.pushObject task

    @set('realTasks', tasks)

    prevState = GG.userController.loadState("town", this)
    @set 'skipSave', true
    for k in Object.keys(prevState)
      @set(k, prevState[k])
    @set 'skipSave', false

  serialize: ->
    {completed: @get('completed'), enabled: @get('enabled')}

  triggerSave: (->
    GG.userController.saveState('town', this) unless @get 'skipSave'
  ).observes('completed', 'enabled')

GG.Task = Ember.Object.extend
  _id: null
  name: null
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
  obstacleCourse: null
  meiosisControl: "all"
  # viewmodel properties
  showQuestionBubble: false
  showSpeechBubble: false
  showFinalMessageBubble: false
  skipSave: false
  reputationEarned: Number.NEGATIVE_INFINITY

  init: ->
    @_super()
    prevState = GG.userController.loadState("task", this)
    @set 'skipSave', true
    for k in Object.keys(prevState)
      @set(k, prevState[k])
    if course = @get "obstacleCourse"
      @set "obstacleCourse", GG.ObstacleCourse.create course
    @set 'skipSave', false

  serialize: ->
    {completed: @get('completed'), reputationEarned: @get('reputationEarned')}

  triggerSave: (->
    GG.userController.saveState('task', this) unless @get 'skipSave'
  ).observes('completed','reputationEarned')

  getShortText: ->
    text = @get('npc.speech.shortText') || @get('npc.speech.text') || ""
    if typeof(text) == 'object'
      # This results in some pretty ugly text...
      # but we only use this if shortText isn't defined.
      text = text.reduce (prev, item, idx, arr)->
        return prev + " " + item
    text = text.replace(/(<([^>]+)>)/ig, " ").replace('drake', Ember.I18n.t('drake'))
    return text

  cleanedUpShortText: (->
    text = @get('npc.speech.shortText') || ""
    return text.replace('drake', Ember.I18n.t('drake'))
  ).property()

GG.Drake = Ember.Object.extend
  visibleGenesBinding: 'GG.drakeController.visibleGenes'
  hiddenGenesBinding: 'GG.drakeController.hiddenGenes'
  revealedAlleles: null
  revealedIdx: 0

  biologicaOrganism : null            # organism object created by GWT
  sex               : null
  imageURL          : null
  bred              : false

  init: ->
    @_super()
    @set 'revealedAlleles', {a: [], b: []}

  species: (->
    @get('biologicaOrganism.species.name')
  ).property('biologicaOrganism')

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
      @set 'revealedIdx', @get('revealedIdx')+1

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

  hasHowManyCharacteristics: (characteristics)->
    gorg = @get 'biologicaOrganism'
    count = 0
    for ch in characteristics
      if ch == "Female" && @get('female')
        count += 1
      else if ch == "Male" && @get('male')
        count += 1
      else if ~gorg.getAllCharacteristics().indexOf ch
        count += 1
    return count

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

# not certain how we want to define our event constants. This will do fine for now
GG.Events =
  # Session events
  STARTED_SESSION : "Started session"
  USER_LOGGED_IN  : "User logged in"
  GROUP_LOGGED_IN : "Group logged in"
  USER_DENIED_GAME: "User denied game access"
  USER_DENIED_BASELINE: "User denied baseline access"

  # Town events
  ENTERED_TOWN    : "Entered town"
  COMPLETED_TOWN  : "Completed town"
  ENABLED_TOWN    : "Enabled town"

  # Task events
  STARTED_TASK    : "Started task"
  COMPLETED_TASK  : "Completed task"
  REPUTATION_CHANGED : "Reputation changed"
  REPUTATION_EARNED : "Reputation earned"

  # Breeding events
  SELECTED_PARENT : "Selected parent"
  REMOVED_PARENT  : "Removed parent"
  BREED_BUTTON_CLICKED : "Breed button clicked"
  BRED_DRAGON     : "Bred dragon"
  BRED_WITH_EXTRA_CYCLE : "Extra breed cycle"
  KEPT_OFFSPRING  : "Kept offspring"
  FREED_OFFSPRING : "Freed offspring"
  SUBMITTED_OFFSPRING : "Submitted offspring"
  REVEALED_ALLELE : "Revealed allele"
  ENABLED_MEIOSIS_CONTROL : "Meiosis control enabled"
  DISABLED_MEIOSIS_CONTROL: "Meiosis control disabled"
  CHOSE_CHROMOSOME: "Chromosome selected"
  DESELECTED_CHROMOSOME: "Chromosome deselected"
  MADE_CROSSOVER  : "Crossover selected"

  #Obstacle course events
  INCOMPLETE_COURSE: "Incomplete obstacle course"

GG.TaskNPC = Ember.Object.extend
  name: null
  imageURL: null
  task: null
  position: null

GG.ActionCosts = Ember.Object.extend
  someEvent: [0]

GG.ObstacleCourse = Ember.Object.extend
  obstacles: null
  path: null
  init: ->
    if obstacles = @get "obstacles"
      obstacleObjs = []
      for obs in obstacles
        if typeof obs is "object"
          obstacleObjs.push GG.Obstacle.create obs
      @set "obstacles", obstacleObjs

GG.Obstacle = Ember.Object.extend
  obstacle: null
  positionX: 0
  positionY: 0

GG.GroupMember = Ember.Object.extend
  name: ""
  schoolID: ""
  serialize: ->
    {name: @get('name'), schoolID: @get('schoolID')}
  validName: (->
    return not @get('invalidName')
  ).property('invalidName')
  invalidName: (->
    name = @get('name')
    return @_null(name) or @_empty(name)
  ).property('name')
  validSchoolID: (->
    return not @get('invalidSchoolID')
  ).property('invalidSchoolID')
  invalidSchoolID: (->
    id = @get('schoolID')
    return @_null(id) or @_empty(id)
  ).property('schoolID')
  _null: (text)->
    return not text?
  _empty: (text)->
    return text.length < 1