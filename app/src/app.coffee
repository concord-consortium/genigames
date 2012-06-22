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

minispade.require 'genigames/templates/parent-pool-view'
minispade.require 'genigames/templates/breeder-view'

# on load
$ ->

  GG.logController.startNewSession()

  # GET /api/game
  # set the player's task according to the game specification
  $.getJSON 'api/game', (data) ->
    task = GG.Task.create data.task
    GG.tasksController.addTask task
    GG.tasksController.setCurrentTask task

  setTimeout ->
    for i in [0..5]
      GenGWT.generateAliveDragonWithSex i%2, (org) ->
        GG.parentController.pushObject GG.Drake.createFromBiologicaOrganism org

  , 2000

  # socket.io hello world stuff
  socket = window.socket = io.connect "#{location.protocol}//#{location.host}/"
  socket.on 'news', (data) ->
    console.log data
    socket.emit 'my other event', my: 'data'
