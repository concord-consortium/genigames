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
    'T': 'Long tail',
    'Tk': 'Kinked tail',
    't': 'Short tail',
    'M': 'Metallic',
    'm': 'Nonmetallic',
    'W': 'Wings',
    'w': 'No wings',
    'H': 'No horns',
    'h': 'Horns',
    'C': 'Colored',
    'c': 'Colorless',
    'Fl': 'Forelimbs',
    'fl': 'No forelimbs',
    'Hl': 'Hindlimbs',
    'hl': 'No hindlimbs',
    'A1': "'A1' armor",
    'A2': "'A2' armor",
    'a': "'a' armor",
    'B': 'Black',
    'b': 'Brown',
    'D': 'Full color',
    'd': 'Dilute color',
    'dl': 'dl',
    'Rh': 'Nose spike',
    'rh': 'No nose spike',
    'Y' : 'Y',
    '' : ''

  ###
    Returns true if the allele passed is a member of the gene, where the
    gene is indeicated by an example allele.
    isMemberOfGene("dl", "D") => true
    isMemberOfGene("rh", "D") => false
  ###
  isMemberOfGene: (allele, exampleOfGene) ->
    for own gene of @geneList
      allelesOfGene = @geneList[gene]
      if ~allelesOfGene.indexOf(allele) && ~allelesOfGene.indexOf(exampleOfGene)
        return true
    false

  ###
    Given an array of alleles and an array of genes, filter the alleles to return only
    those in the array of genes.
    filter(["TK", "m", "W", "dl"], ["T", "D"]) => ["TK", "dl"]
  ###
  filter: (alleles, filter) ->
    alleles.filter (allele) =>
      for gene in filter
        if @isMemberOfGene(allele, gene)
          return true
      false

  filterGenotype: (genotype, filter) ->
    return {a: @filter(genotype.a, filter), b: @filter(genotype.b, filter)}
