GG.MainView = Ember.View.extend
  templateName: 'main-view'


GG.DrakeView = Ember.View.extend
  tagName            : 'img'
  attributeBindings  : ['src', 'width']
  srcBinding         : 'content.imageURL'
  width              : 200


GG.ParentPoolView = Ember.View.extend
  children: null

  drakeSelected: (evt) ->
    drake = evt.context
    GG.parentController.selectParent drake


GG.AllelesView = Ember.View.extend
  tagName: 'span'

  allelesString: (->
    genotype = @getPath 'content.visibleGenotype'
    genotype.a.concat(genotype.b).join(',')
  ).property('content.visibleGenotype').cacheable()