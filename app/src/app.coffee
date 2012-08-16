minispade.require 'genigames/vendor/jquery'
minispade.require 'genigames/vendor/jquery-ui'
minispade.require 'genigames/vendor/jquery-css-transform'
minispade.require 'genigames/vendor/jquery-animate-css-rotate-scale'
minispade.require 'genigames/vendor/jquery-bgpos'
minispade.require 'genigames/vendor/ember'

window.GG = GG = Ember.Application.create()

GG.MALE   = 0
GG.FEMALE = 1

minispade.require 'genigames/gen-gwt'
minispade.require 'genigames/genetics'

minispade.require 'genigames/models'
minispade.require 'genigames/controllers'
minispade.require 'genigames/views'
minispade.require 'genigames/statemanager'

minispade.require 'genigames/templates/town'
minispade.require 'genigames/templates/parent-pool-view'
minispade.require 'genigames/templates/breeder-view'
minispade.require 'genigames/templates/chromosome-panel'
minispade.require 'genigames/templates/chromosome'
minispade.require 'genigames/templates/move-counter'

# on load
$ ->

  GG.logController.startNewSession()

  # GET /api/game
  # set the player's task according to the game specification
  $.getJSON 'api/game', (data) ->
    for t in data.tasks
      task = GG.Task.create t
      GG.tasksController.addTask task
    GG.statemanager.goToState 'inTown'

  # socket.io hello world stuff
  socket = window.socket = io.connect "#{location.protocol}//#{location.host}/"
  socket.on 'news', (data) ->
    console.log data
    socket.emit 'my other event', my: 'data'
