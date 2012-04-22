GG.Task = Ember.Object.extend
  visibleGenes: null


GG.Drake = Ember.Object.extend
  # Dependencies on globals should be made explicit via a bindings prologue at the beginning of
  # an object definition.
  currentTaskBinding: 'GG.tasksController.currentTask'

  biologicaOrganism : null            # organism object created by GWT
  sex               : null
  imageURL          : null

  genotype: (->
    alleleString = @getPath 'biologicaOrganism.alleles'

    a: alleleString.match(/a:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
    b: alleleString.match(/b:([^,])*/g).map (short) -> short.match(/[^:]+$/)[0]
  ).property('biologicaOrganism').cacheable()

  visibleGenotype: (->
    visibleGenes = GG.tasksController.getPath 'currentTask.visibleGenes'

    GG.genetics.filterGenotype @get('genotype'), visibleGenes
  ).property('genotype', 'currentTask').cacheable()

# a helper for creating a GG.Drake from a Biologica/GWT organism object
GG.Drake.createFromBiologicaOrganism = (org) ->
  GG.Drake.create
    biologicaOrganism: org
    imageURL         : org.imageURL
    sex              : org.sex