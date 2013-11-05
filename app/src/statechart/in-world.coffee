GG.StateInWorld = Ember.State.extend

  initialState: 'townsWaiting'

  enter: ->
    GG.universeView.setCurrentView 'world'

  spriteAnimation: null

  navigateToTown: (manager, town) ->
    prevTown = GG.townsController.get('currentTown')
    changed = GG.townsController.setCurrentTown(town)
    # navigateTime = 100
    # if changed and prevTown?
    #   navigateTime = 4000
    #   spriteFrame = 1
    #   animateSprite = ->
    #     spriteFrame++
    #     top = 72 * (spriteFrame % 8)
    #     $('.dragon').css('backgroundPosition','-0px -'+top+'px')
    #   spriteAnimation = setInterval(animateSprite,50)
    #   if (prevTown.get('position') < town.get('position'))
    #     $("#dragon-right").attr("id","dragon-left")
    #   else
    #     $("#dragon-left").attr("id","dragon-right")
    #   # dragon take off, spin the world, land if we're not already at that town
    #   # $('.dragon').animate({left: "-=20px", top: "-=30px"}, {duration: 400, complete: ->
    #   #   $('#world').animate({rotate: town.get('position')}, {duration: navigateTime, complete: ->
    #   #     $('.dragon').animate({left: "+=20px", top: "+=30px"}, {duration: 400, complete: ->
    #   #       clearInterval(spriteAnimation)
    #   #       spriteFrame = 1
    #   #       animateSprite()
    #   #     })
    #   #   })
    #   # })
    # setTimeout =>
    manager.transitionTo 'inTown'
    # , navigateTime+1000

  townsWaiting: Ember.State.create
    townSelected: (manager, town) ->
      if not town.get('locked')
        manager.send 'navigateToTown', town
      else
        manager.send 'openTownPassword', town

    unlockTown: (manager) ->
      pass = GG.manualEventController.get 'password'
      GG.manualEventController.set 'password', ""

      return unless pass

      pass13 = pass.replace /[a-zA-Z]/g, (c) ->
        String.fromCharCode if ((if c <= "Z" then 90 else 122)) >= (c = c.charCodeAt(0) + 13) then c else c - 26
      if pass13 is "tra1tnzrf"  # top s33cret.....
        GG.townsController.unlockTown()
        manager.send 'closeAdminPanel'

  movingDirectlyToNextTown: Ember.State.create
    # setup is called after we have fully entered the state, so we can call actions
    # fixme: the animation sitll won't work without the timeout below
    setup: (manager) ->
      currTown = GG.townsController.get('currentTown')
      towns = currTown.get('otherTowns')
      idx = towns.indexOf(currTown)
      if (towns[idx+1])
        setTimeout =>
          manager.send 'navigateToTown', towns[idx+1]
        , 50
