GG.BreederView = Ember.View.extend
  templateName: 'breeder-view'


GG.DrakeView = Ember.View.extend
  tagName            : 'img'
  attributeBindings  : ['src', 'width']
  srcBinding         : 'content.imageURL'
  width              : 200


GG.ParentPoolView = Ember.View.extend
  templateName: 'parent-pool-view'
  contentBinding: 'controller.content'

  drakeSelected: (evt) ->
    drake = evt.context
    @get('controller').drakeSelected drake

GG.FatherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.fatherPoolController'

GG.MotherPoolView = GG.ParentPoolView.extend
  controllerBinding: 'GG.motherPoolController'


GG.AllelesView = Ember.View.extend
  tagName: 'span'

  allelesString: (->
    genotype = @getPath 'content.visibleGenotype'
    genotype.a.concat(genotype.b).join(',') unless !genotype
  ).property('content.visibleGenotype').cacheable()