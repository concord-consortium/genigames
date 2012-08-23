GG.Task = Ember.Object.extend
  visibleGenes: null
  hiddenGenes: null
  initialDrakes: null
  targetDrake: null
  targetCount: 1
  npc: null
  showQuestionBubble: false
  showSpeechBubble: false
  showCompletionBubble: false
  completed: false
  matchCount: 0

  isComplete: ->
    # parse required characteristics
    parsedCharacteristics = @get('targetDrake').split(/\s*,\s*/).map (ch, idx, arr)->
      ch = ch.toLowerCase()
      ch.charAt(0).toUpperCase() + ch.slice(1)
    parsedCharacteristics.unshift("Alive") unless parsedCharacteristics.contains("Alive")
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
    alleleString = @getPath 'biologicaOrganism.alleles'

    a: alleleString.match(/a:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
    b: alleleString.match(/b:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
  ).property('biologicaOrganism')

  visibleGenotype: (->
    if @get('visibleGenes')?
      vis = GG.genetics.filterGenotype @get('genotype'), @get('visibleGenes')
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
      hid = GG.genetics.filterGenotype @get('genotype'), @get('hiddenGenes')
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
        has = GenGWT.hasCharacteristic(gorg, ch)
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
    imageURL         : org.imageURL
    sex              : org.sex

GG.LogEvent = Ember.Object.extend
  user        : null
  session     : null
  time        : null
  event       : null
  parameters  : null

# not certain how we want to define our event constants. This will do fine for now
GG.Events =
  STARTED_SESSION : "Started session"
  STARTED_TASK    : "Started task"
  SELECTED_PARENT : "Selected parent"
  REMOVED_PARENT  : "Removed parent"
  SELECTED_OFFSPRING : "Selected offspring"
  BRED_DRAGON     : "Bred dragon"

GG.TaskNPC = Ember.Object.extend
  name: null
  imageURL: null
  task: null
