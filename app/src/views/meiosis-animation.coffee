GG.MeiosisAnimation = Ember.Object.create
  timeScale: 1
  animation: 0
  stage: "not started"
  parent: "unknown"

  scale: (baseTime)->
    return baseTime * @get('timeScale')

  # if we've reset between when this was registered and when it's to be
  # executed, don't execute it
  registerTimeout: (delay, callback)->
    registeredAnimation = @get 'animation'
    setTimeout =>
      currentAnimation = @get 'animation'
      if currentAnimation == registeredAnimation
        callback.call()
    , delay

  ###
    chromosomeContainerName: e.g. '#parent-fathers-pool-container'
  ###
  reset: (chromosomeContainerName, parentView) ->
    @set('animation', @get('animation')+1)
    parentView.rerender()

  animate: (chromosomeContainerName, parentView, callback) ->
    args = {
      parentView: parentView,
      callback: callback
    }

    args.mainContainer = $("#{chromosomeContainerName}")
    args.container = args.mainContainer.find('.chromosome-panel')
    args.cell = args.container.find('.mainCell')

    @set('parent', if parentView.get('content.female') then "mother" else "father")
    @set('stage', "pre-gamete selection")

    meiosisControl = GG.tasksController.get 'currentTask.meiosisControl'

    # duplicate each chromosome into sister chromatids (prophase I)
    args.container.find('.sister-1,.sister-2').each (i, chromo) ->
      $chromo = $(chromo)
       #$chromo.find('.alleles-container').remove()
      left = $chromo.css("left")
      if (left == "auto") then left = 0
      $chromo.css({left: left})
      # $chromo.css({left: "+=30px"})

    args.container.find('.sister-2').removeClass('hidden')

    @separateChromatids(args)

    # flip chromo-2 order (independent assortment) (note, this is Metaphase I and should be after crossover)
    # container.find('.chromo-2:not(.right)').animate({left: "+=47px"}, 200)
    # container.find('.chromo-2.right').animate({left: "-=47px"}, 200)
    # container.find('.chromo-2.right').removeClass("right").addClass("tempNotRight")
    # container.find('.chromo-2:not(.tempNotRight)').addClass("right")
    # container.find('.chromo-2.tempNotRight').removeClass("tempNotRight")
    @registerTimeout @scale(500), =>
      if GG.breedingController.get('breedType') == GG.BREED_CONTROLLED and
          (meiosisControl is "crossover" or meiosisControl is "all")
        args.parentView.selectingCrossover =>
          if meiosisControl is "selection" or meiosisControl is "all"
            args.parentView.selectingChromatids =>
              @divide(args)
          else
            @divide(args)
      else
        args.parentView.crossOver()

        # divide cell first time (Anaphase I + Telophase I)
        @registerTimeout @scale(2000), =>
          GG.tutorialMessageController.showMeiosisDivisionTutorial =>
            if GG.breedingController.get('breedType') == GG.BREED_CONTROLLED and
                (meiosisControl is "selection")
              args.parentView.selectingChromatids =>
                @divide(args)
            else
              @divide(args)

  separateChromatids: (args)->
    t = @scale(600)
    # separate chromatids
    i = -1
    offset = 16
    for ch in ['.chromo-1','.chromo-2','.chromo-X']
      offset += 20
      for side in ['.left','.right']
        for sis in ['.sister-1','.sister-2']
          i++
          args.container.find(ch + sis + side).animate({left: i*30 + offset}, t, 'easeInOutQuad')
    args.container.find('.chromo-Y.sister-1.right').animate({left: 376}, t, 'easeInOutQuad')
    args.container.find('.chromo-Y.sister-2.right').animate({left: 406}, t, 'easeInOutQuad')
    args.cell.animate({width: 450}, t, 'easeInOutQuad')

    parent = if args.parentView.get('content.female') then "mother" else "father"

    if parent is "father"
      $('#chromosome-labels-meiosis').attr('class', 'mother')
    else
      $('#chromosome-labels-meiosis').removeClass('mother')
      $('#chromosome-labels-meiosis').hide()
    @registerTimeout t/2, =>
      $('#chromosome-labels-meiosis-long').attr('class', parent).fadeIn(t*2)

  divide: (args)->
    # move homologous pairs apart
    # line up sister chromatids along center line (Metaphase II)
    t = @scale(800)

    $('#chromosome-labels-meiosis-long').fadeOut(t/3)

    if args.parentView.get('motherFather') is 'mother'
      args.container.animate({top: "-=70px"}, t, 'easeInOutQuad')
    args.container.find('.chromo-1.cell0').animate({top: 0, left: 36}, t, 'easeInOutQuad')
    args.container.find('.chromo-1.cell2').animate({top: 0, left: 66}, t, 'easeInOutQuad')
    args.container.find('.chromo-1.cell1').animate({top: 105, left: 36}, t, 'easeInOutQuad')
    args.container.find('.chromo-1.cell3').animate({top: 105, left: 66}, t, 'easeInOutQuad')

    args.container.find('.chromo-2.cell0').animate({top: 0, left: 116}, t, 'easeInOutQuad')
    args.container.find('.chromo-2.cell2').animate({top: 0, left: 146}, t, 'easeInOutQuad')
    args.container.find('.chromo-2.cell1').animate({top: 105, left: 116}, t, 'easeInOutQuad')
    args.container.find('.chromo-2.cell3').animate({top: 105, left: 146}, t, 'easeInOutQuad')

    args.container.find('.chromo-X.cell0, .chromo-Y.cell0').animate({top: 0, left: 196}, t, 'easeInOutQuad')
    args.container.find('.chromo-X.cell2, .chromo-Y.cell2').animate({top: 0, left: 226}, t, 'easeInOutQuad')
    args.container.find('.chromo-X.cell1, .chromo-Y.cell1').animate({top: 105, left: 196}, t, 'easeInOutQuad')
    args.container.find('.chromo-X.cell3, .chromo-Y.cell3').animate({top: 105, left: 226}, t, 'easeInOutQuad')

    # make cell taller
    args.cell.animate({left: "-=5px", top: "-=2px", height: 200, width: 285}, t, 'easeInOutQuad')
    #divide cell
    @registerTimeout t, =>
      @splitCell(args)

    @registerTimeout 1.75*t, =>
      @separateToGametes(args)

  splitCell: (args)->
    t = @scale(300)
    args.container.find('.mainCell').remove()
    args.container.append($("<div class='cell cell-top'>").css({height: 200, width: 300, zIndex: -3}))
    args.container.append($("<div class='cell cell-bottom'>").css({height: 200, width: 300, zIndex: -3}))
    args.container.find('.cell-top').animate({height: 65, top: 2, width: 300}, t, 'easeInOutQuad')
    args.container.find('.cell-bottom').animate({height: 65, top: 108, width: 300}, t, 'easeInOutQuad')

  separateToGametes: (args)->
    t = @scale(2000)
    # move sisters apart to divide cell again (Anaphase II + Telophase II)
    args.container.find('.chromo-1.cell0,.chromo-1.cell1').animate({left: 10}, t, 'easeInOutQuad')
    args.container.find('.chromo-2.cell0,.chromo-2.cell1').animate({left: 41}, t, 'easeInOutQuad')
    args.container.find('.chromo-X.cell0,.chromo-X.cell1,.chromo-Y.cell0,.chromo-Y.cell1').animate({left: 72}, t, 'easeInOutQuad')

    args.container.find('.chromo-1.cell2,.chromo-1.cell3').animate({left: 186}, t, 'easeInOutQuad')
    args.container.find('.chromo-2.cell2,.chromo-2.cell3').animate({left: 217}, t, 'easeInOutQuad')
    args.container.find('.chromo-X.cell2,.chromo-X.cell3,.chromo-Y.cell2,.chromo-Y.cell3').animate({left: 248}, t, 'easeInOutQuad')

    #divide cell
    @divideCell(args)

  divideCell: (args)->
    t = @scale(2000)
    args.container.find('.cell').remove()
    args.container.append($("<div class='cell cell-left cell-top'>").css({top: 2, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-top'>").css({top: 2, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-left cell-bottom'>").css({top: 108, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-bottom'>").css({top: 108, height: 65, zIndex: -2}))
    args.container.find('.cell-left').animate({width:145, left: -15}, t, 'easeInOutQuad')
    args.container.find('.cell-right').animate({width:145, left: 158}, t, 'easeInOutQuad')

    @registerTimeout t, =>
      GG.tutorialMessageController.showMeiosisGameteTutorial =>
        @chooseGamete(args)
      , args.parentView.get('motherFather')

  chooseGamete: (args)->
    lastGamete = -1
    pickRandomGamete = =>
      args.container.find(".cell").addClass 'not-chosen'
      gamete = ExtMath.randomInt(4) while (gamete is lastGamete or gamete < 0)
      lastGamete = gamete
      left = gamete is 0 or gamete is 1
      top  = gamete is 0 or gamete is 2
      horizontal = if left then "left" else "right"
      vertical   = if top  then "top" else "bottom"
      chosenCell = ".cell-#{horizontal}.cell-#{vertical}"
      args.container.find(chosenCell).removeClass 'not-chosen'

    times = [90]
    times.push(times[i-1]+90) for i in [1..5]
    times.push(times[i-1]+120) for i in [6..9]
    times.push(times[i-1]+180) for i in [10..12]
    for t in times
      @registerTimeout @scale(t), pickRandomGamete

    @registerTimeout @scale(1800), =>
      args.container.find(".cell").addClass 'not-chosen'
      gamete = args.parentView.get('randomGameteNumber')
      left = gamete is 0 or gamete is 1
      top  = gamete is 0 or gamete is 2
      horizontal = if left then "left" else "right"
      vertical   = if top  then "top" else "bottom"
      chosenCell = ".cell-#{horizontal}.cell-#{vertical}"
      chosenChromos = ".cell" + gamete
      leftShift = (if left then "+=" else "-=" ) + "88px"
      topShift = (if top then "+=" else "-=" ) + "55px"

      args.container.find(chosenCell).removeClass 'not-chosen'

      @set('stage', "post-gamete selection")

      t = @scale(1000)

      args.container.find(chosenChromos).animate({left: leftShift, top: 50}, t, 'easeInOutQuad')
      args.container.find(".chromosome:not(" + chosenChromos + ")").animate({opacity: 0}, 0.7*t)
      args.container.find(chosenCell).animate({top: 47, left: 73, height: 75}, t, 'easeInOutQuad')
      args.container.find(".cell:not(.mainCell):not(" + chosenCell + ")").animate({opacity: 0}, 0.7*t)
      @registerTimeout 0.7*t, ->
        args.container.find(".chromosome:not(" + chosenChromos + ")").hide()
        args.container.find(".cell:not(.mainCell):not(" + chosenCell + ")").remove()
      if args.callback?
        @registerTimeout 1.1*t, ->
          args.callback()

  mergeChosenGametes: (fatherContainerName, motherContainerName, callback)->
    fatherContainer = $(fatherContainerName)
    motherContainer = $(motherContainerName)

    # at this point, the animation should be complete, so the chosen gametes will
    # be centered in the MeiosisView area. We need to move them toward each other,
    # and then combine them into a single cell arranged like the normal chromosome
    # panel view.
    # TODO

    t = @scale(600)
    # move the father cell down, mother cell up; expand the cells
    fatherContainer.find('.cell:not(.mainCell)').animate({top: "+=88px", left: "-=15px", width: 300, height: 120}, t, 'easeInOutQuad')
    motherContainer.find('.cell:not(.mainCell)').animate({top: "-=79px", left: "-=15px", width: 300, height: 120}, t, 'easeInOutQuad')

    # move the father chromos down, mothers up, and reposition
    fatherContainer.find('.chromo-1').animate({top: 163, left: "+=32px"}, t, 'easeInOutQuad')
    fatherContainer.find('.chromo-2').animate({top: 163, left: "+=75px"}, t, 'easeInOutQuad')
    fatherContainer.find('.chromo-X,.chromo-Y').animate({top: 163, left: "+=118px"}, t, 'easeInOutQuad')

    motherContainer.find('.chromo-1').animate({top: -5}, t, 'easeInOutQuad')
    motherContainer.find('.chromo-2').animate({top: -5, left: "+=45px"}, t, 'easeInOutQuad')
    motherContainer.find('.chromo-X').animate({top: -5, left: "+=90px"}, t, 'easeInOutQuad')

    @registerTimeout t, ->
      motherContainer.find('.cell').remove()

    @registerTimeout 1.5*t, ->
      GG.tutorialMessageController.showMeiosisFertilizationTutorial ->
        callback()
