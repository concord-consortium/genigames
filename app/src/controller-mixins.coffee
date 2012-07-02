###
  Creates a first-in-first-out fixed-length controller.
  Note: for now this only works when pushObject is called
###
GG.fifoArrayController = Ember.Mixin.create
  maxLength: -1
  pushObject: ->
    maxLength = @get 'maxLength'
    if (maxLength > -1 and @get('length') >= maxLength)
      @removeObject(@get 'firstObject')
    @_super.apply(this, arguments);
