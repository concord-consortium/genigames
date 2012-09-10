GG.StateInWorld = Ember.State.extend

  initialState: 'townsWaiting'

  enter: ->
    # load the game after we log in so that we can create towns and tasks
    # with the current user's saved state
    loadGame = ->
      # GET /api/game
      # set the player's task according to the game specification
      gamePath = if UNDER_TEST? then 'api/testgame' else 'api/game'
      $.getJSON gamePath, (data) ->
        for to in data.towns
          town = GG.Town.create to
          GG.townsController.addTown town
        GG.universeView.set 'currentView', GG.universeView.get 'world'
        currentTown = GG.townsController.get('currentTown')
        if currentTown?
          setTimeout ->
            $('#world').rotate(currentTown.get('position') + "deg")
          , 10

    if GG.statemanager.get('params').learner?
      obs = ->
        GG.userController.removeObserver('loaded', obs)
        loadGame()
      GG.userController.addObserver('loaded', obs)
      GG.userController.set('learnerId', GG.statemanager.get('params').learner)
    else
      loadGame()

  townsWaiting: Ember.State.create
    spriteAnimation: null
    townSelected: (manager, town) ->
      if town.get('enabled')
        prevTown = GG.townsController.get('currentTown')
        changed = GG.townsController.setCurrentTown(town)
        navigateTime = 100
        if changed and prevTown?
          navigateTime = 4000
          spriteFrame = 1
          animateSprite = ->
            spriteFrame++
            top = 72 * (spriteFrame % 8)
            $('.dragon').css('backgroundPosition','-0px -'+top+'px')
          spriteAnimation = setInterval(animateSprite,50)
          if (prevTown.get('position') < town.get('position'))
            $("#dragon-right").attr("id","dragon-left")
          else
            $("#dragon-left").attr("id","dragon-right")
          # dragon take off, spin the world, land if we're not already at that town
          $('.dragon').animate({left: "-=20px", top: "-=30px"}, {duration: 400, complete: ->
            $('#world').animate({rotate: town.get('position')}, {duration: navigateTime, complete: ->
              $('.dragon').animate({left: "+=20px", top: "+=30px"}, {duration: 400, complete: ->
                clearInterval(spriteAnimation)
                spriteFrame = 1
                animateSprite()
              })
            })
          })
        setTimeout =>
          manager.transitionTo 'inTown'
        , navigateTime+1200