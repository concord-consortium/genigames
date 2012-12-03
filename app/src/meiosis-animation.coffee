GG.MeiosisAnimation = Ember.Object.create
  timeScale: 1
  animation: 0

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
      if GG.breedingController.get('breedType') == GG.BREED_CONTROLLED
        args.parentView.selectingCrossover =>
          args.parentView.selectingChromatids =>
            @divide(args)
      else
        args.parentView.crossOver()

        # divide cell first time (Anaphase I + Telophase I)
        @registerTimeout 2000, =>
          @divide(args)

  separateChromatids: (args)->
    t = @scale(400)
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

  divide: (args)->
    # move homologous pairs apart
    # line up sister chromatids along center line (Metaphase II)
    t = @scale(800)
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

    # widen cell
    args.cell.animate({height: 200, width: 300}, t, 'easeInOutQuad')
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
    args.container.find('.cell-top').animate({height: 65, top: -5, width: 300}, t, 'easeInOutQuad')
    args.container.find('.cell-bottom').animate({height: 65, top: 102, width: 300}, t, 'easeInOutQuad')

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
    args.container.append($("<div class='cell cell-left cell-top'>").css({top: -5, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-top'>").css({top: -5, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-left cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
    args.container.find('.cell-left').animate({width:145, left: -15}, t, 'easeInOutQuad')
    args.container.find('.cell-right').animate({width:145, left: 158}, t, 'easeInOutQuad')

    @registerTimeout t, =>
      @chooseGamete(args)

  chooseGamete: (args)->
    # TODO eventually let students choose
    # container.find('.cell').click (evt)->
    #   console.log("cell click complete", evt)
    # enlarge the chosen gamete
    # and make the rest disappear
    gamete = args.parentView.get('randomGameteNumber')
    chosenChromos = ""
    chosenCell = ""
    down = true
    right = true
    if gamete == 0
      chosenCell = ".cell-left.cell-top"
    else if gamete == 1
      chosenCell = ".cell-left.cell-bottom"
      down = false
    else if gamete == 2
      chosenCell = ".cell-right.cell-top"
      right = false
    else if gamete == 3
      chosenCell = ".cell-right.cell-bottom"
      down = false
      right = false
    chosenChromos = ".cell" + gamete
    leftShift = (if right then "+=" else "-=" ) + "88px"
    topShift = (if down then "+=" else "-=" ) + "55px"

    t = @scale(1000)

    args.container.find(chosenChromos).animate({left: leftShift, top: 50}, t, 'easeInOutQuad')
    args.container.find(".chromosome:not(" + chosenChromos + ")").animate({opacity: 0}, 0.7*t)
    args.container.find(chosenCell).animate({top: 50, left: 73}, t, 'easeInOutQuad')
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
    motherContainer.find('.cell:not(.mainCell)').animate({top: "-=129px", left: "-=15px", width: 300, height: 120}, t, 'easeInOutQuad')

    # move the father chromos down, mothers up, and reposition
    fatherContainer.find('.chromo-1').animate({top: 163, left: "+=32px"}, t, 'easeInOutQuad')
    fatherContainer.find('.chromo-2').animate({top: 163, left: "+=75px"}, t, 'easeInOutQuad')
    fatherContainer.find('.chromo-X,.chromo-Y').animate({top: 163, left: "+=118px"}, t, 'easeInOutQuad')

    motherContainer.find('.chromo-1').animate({top: -55}, t, 'easeInOutQuad')
    motherContainer.find('.chromo-2').animate({top: -55, left: "+=45px"}, t, 'easeInOutQuad')
    motherContainer.find('.chromo-X').animate({top: -55, left: "+=90px"}, t, 'easeInOutQuad')

    @registerTimeout t, ->
      motherContainer.find('.cell').remove()

    @registerTimeout 1.5*t, ->
      callback()
