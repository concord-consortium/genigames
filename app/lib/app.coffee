minispade.require 'genigames/vendor/jquery'
minispade.require 'genigames/vendor/ember'

window.GG = GG = Ember.Application.create()

GG.MALE   = 0
GG.FEMALE = 1

minispade.require 'genigames/gen-gwt'
minispade.require 'genigames/genetics'

minispade.require 'genigames/models'
minispade.require 'genigames/controllers'
minispade.require 'genigames/views'

minispade.require 'genigames/templates/main-view'

# on load
$ ->
  # create sample task
  task = GG.Task.create
    visibleGenes: ['T']

  GG.tasksController.addTask task
  GG.tasksController.setCurrentTask task

  # create initial parents, after waiting half a second for GWT to load
  setTimeout ->
    for i in [0..5]
      GenGWT.generateAliveDragonWithSex i%2, (org) ->
        GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

  , 2000
