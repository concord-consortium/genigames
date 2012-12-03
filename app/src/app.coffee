minispade.require 'genigames/vendor/jquery'
minispade.require 'genigames/vendor/jquery-ui'
minispade.require 'genigames/vendor/jquery-css-transform'
minispade.require 'genigames/vendor/jquery-animate-css-rotate-scale'
minispade.require 'genigames/vendor/jquery-bgpos'
minispade.require 'genigames/vendor/jquery-imagesloaded'
minispade.require 'genigames/vendor/handlebars'
minispade.require 'genigames/vendor/ember'
minispade.require 'genigames/vendor/biologica'

window.GG = GG = Ember.Application.create()

GG.MALE   = 0
GG.FEMALE = 1
GG.imageNameStart = "/resources/drakes/images/"

minispade.require 'genigames/models'
minispade.require 'genigames/controllers'
minispade.require 'genigames/views'
minispade.require 'genigames/statemanager'

minispade.require 'genigames/templates/world'
minispade.require 'genigames/templates/town'
minispade.require 'genigames/templates/parent-pool-view'
minispade.require 'genigames/templates/breeder-view'
minispade.require 'genigames/templates/chromosome-panel'
minispade.require 'genigames/templates/chromosome'
minispade.require 'genigames/templates/move-counter'
minispade.require 'genigames/templates/match-goal-counter'
minispade.require 'genigames/templates/login'
minispade.require 'genigames/templates/drake'
minispade.require 'genigames/templates/choose-class'
minispade.require 'genigames/templates/meiosis'
minispade.require 'genigames/templates/obstacle-course'

# works similar to :contains(), but requires the whole content
# (whitespace removed from beginning and end) to match
# not just part
$.expr[":"].onlyContains = (obj, index, meta, stack)->
  return (obj.textContent || obj.innerText || $(obj).text() || "").replace(/^\s+/, '').replace(/\s+$/,'') is meta[3]

Ember.Handlebars.registerHelper 'meiosisDefaults', (path, options) ->
  options.hash.gametesBinding = "view.gametes"
  options.hash.useGameteBinding = "view.useGametes"
  options.hash.contentBinding = "view.content"
  options.hash.allelesClickableBinding = "view.allelesClickable"
  options.hash.selectableBinding = "view.chromosomesSelectable"
  return Ember.Handlebars.helpers.view(path, options)

# on load
$ ->

  GG.logController.startNewSession()

  GG.DrakeSpecies = BioLogica.Species.GGDrake
  GG.Genetics = new BioLogica.Genetics GG.DrakeSpecies

  # process url query params
  urlParams = {}
  finder = ->
    match = null
    pl = /\+/g
    search = /([^&=]+)=?([^&]*)/g
    decode = (s)->
      decodeURIComponent(s.replace(pl, " "))
    query = window.location.search.substring(1)

    while match = search.exec(query)
      urlParams[decode match[1]] = decode match[2]
  finder()
  GG.statemanager.set('params', urlParams)

  GG.universeView = Ember.ContainerView.create
    login: GG.LoginView.create()
    chooseClass: GG.ChooseClassView.create()
    world: GG.WorldView.create()
    course: GG.ObstacleCourseView.create()
    town: Ember.ContainerView.create
      town: GG.TownView
      breeder: GG.BreederView
      childViews: ['town','breeder']

  GG.universeView.appendTo('#container')

  GG.statemanager.transitionTo 'loggingIn'

  # socket.io hello world stuff
  socket = window.socket = io.connect "#{location.protocol}//#{location.host}/"
  socket.on 'news', (data) ->
    console.log data
    socket.emit 'my other event', my: 'data'
