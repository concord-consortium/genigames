GG.Task = Ember.Object.extend
  visibleGenes: null


GG.Drake = Ember.Object.extend
  visibleGenesBinding: 'GG.drakeController.visibleGenes'

  biologicaOrganism : null            # organism object created by GWT
  sex               : null
  imageURL          : null

  genotype: (->
    alleleString = @getPath 'biologicaOrganism.alleles'

    a: alleleString.match(/a:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
    b: alleleString.match(/b:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
  ).property('biologicaOrganism').cacheable()

  visibleGenotype: (->
    GG.genetics.filterGenotype @get('genotype'), @get('visibleGenes') unless !@get('visibleGenes')
  ).property('genotype', 'visibleGenes').cacheable()

  female: (->
    @get('sex') == GG.FEMALE
  ).property('sex')

  male: (->
    @get('sex') == GG.MALE
  ).property('sex')

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
  BRED_DRAGON     : "Bred dragon"
