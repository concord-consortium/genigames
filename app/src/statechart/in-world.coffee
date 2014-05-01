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
        manager.send 'openTownUnlocker', town

    payForTown: (manager) ->
      if GG.townsController.get('canPayForNextTown')
        $('#admin-password').hide()
        $('#admin-password-success').show()
        user = GG.userController.get 'user'
        user.set 'reputation', (user.get('reputation') - GG.townsController.get('nextTownsCost'))
        GG.logController.logEvent GG.Events.PAID_TOWN, name: GG.townsController.get 'townToBeUnlocked.name'
        GG.townsController.unlockTown()
        setTimeout =>
          manager.send 'closeAdminPanel'
          manager.send 'navigateToTown', GG.townsController.get('townToBeUnlocked')
        , 1200

    unlockTown: (manager) ->
      pass = GG.manualEventController.get 'password'
      GG.manualEventController.set 'password', ""

      return unless pass

      if pass is GG.townsController.get('townToBeUnlocked.password')
        GG.townsController.unlockTown()
        manager.send 'closeAdminPanel'
        setTimeout =>
          manager.send 'navigateToTown', GG.townsController.get('townToBeUnlocked')
        , 700

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
