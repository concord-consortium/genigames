GG.genetics =

  geneList:
    tail:       ['T', 'Tk', 't'],
    metalic:    ['M', 'm'],
    wings:      ['W', 'w'],
    horns:      ['H', 'h'],
    color:      ['C', 'c'],
    forelimbs:  ['Fl', 'fl'],
    hindlimbs:  ['Hl', 'hl'],
    armor:      ['A1', 'A2', 'a'],
    black:      ['B', 'b'],
    dilute:     ['D', 'd', 'dl'],
    nose:       ['Rh', 'rh']

  alleleLabelMap:
    'T': 'long tail',
    'Tk': 'kinked tail',
    't': 'short tail',
    'M': 'metallic',
    'm': 'nonmetallic',
    'W': 'wings',
    'w': 'no wings',
    'H': 'no horns',
    'h': 'horns',
    'C': 'colored',
    'c': 'colorless',
    'Fl': 'forelimbs',
    'fl': 'no forelimbs',
    'Hl': 'hindlimbs',
    'hl': 'no hindlimbs',
    'A1': "'a1' armor",
    'A2': "'a2' armor",
    'a': "'a' armor",
    'B': 'black',
    'b': 'brown',
    'D': 'full color',
    'd': 'dilute color',
    'dl': 'dl',
    'Rh': 'nose spike',
    'rh': 'no nose spike',
    'Y' : 'y',
    '' : ''

  chromosomeGeneMap:
    '1': ['t','m','w']
    '2': ['h', 'c', 'fl', 'hl', 'a']
    'X': ['b', 'd', 'rh']
    'Y': []

  ###
    Returns true if the allele passed is a member of the gene, where the
    gene is indeicated by an example allele.
    isAlleleOfGene("dl", "D") => true
    isAlleleOfGene("rh", "D") => false
  ###
  isAlleleOfGene: (allele, exampleOfGene) ->
    for own gene of @geneList
      allelesOfGene = @geneList[gene]
      if ~allelesOfGene.indexOf(allele) && ~allelesOfGene.indexOf(exampleOfGene)
        return true
    false

  ###
    Finds the chromosome that a given allele is part of
  ###
  findChromosome: (allele) ->
    for chromosome, genes of @chromosomeGeneMap
      for gene in genes
        return chromosome if @isAlleleOfGene(allele, gene)
    false

  ###
    Given an array of alleles and an array of genes, filter the alleles to return only
    those in the array of genes, and return them in the same order as the filter.
    filter(["TK", "m", "W", "dl"], ["T", "D"]) => ["TK", "dl"]
  ###
  filter: (alleles, filter) ->
    result = []
    for allele in alleles
      for gene in filter
        if @isAlleleOfGene(allele, gene)
          result[filter.indexOf(gene)] = allele
          break
    result.filter (item)=>
      item?

  filterGenotype: (genotype, filter) ->
    return {a: @filter(genotype.a, filter), b: @filter(genotype.b, filter)}
