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

# a helper for creating a GG.Drake from a Biologica/GWT organism object
GG.Drake.createFromBiologicaOrganism = (org) ->
  GG.Drake.create
    biologicaOrganism: org
    imageURL         : org.imageURL
    sex              : org.sex