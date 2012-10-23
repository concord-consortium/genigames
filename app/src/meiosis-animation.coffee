GG.MeiosisAnimation = Ember.Object.create
  timeScale: 1

  scale: (baseTime)->
    return baseTime * @get('timeScale')

  ###
    chromosomeContainerName: e.g. '#parent-fathers-pool-container'
  ###
  reset: (chromosomeContainerName) ->
    mainContainer = $(chromosomeContainerName)
    mainContainer.find(".chromosome").css({opacity: 1, width: "", height: "", top: "", left: ""})
    mainContainer.find(".chromosome").show()
    mainContainer.find(".cell:not(.mainCell)").remove()
    mainContainer.find(".mainCell").css({opacity: 1, width: "", height: "", top: "", left: ""}).show()

  animate: (chromosomeContainerName, parentView, callback) ->
    args = {parentView: parentView, callback: callback}
    args.mainContainer = $("#{chromosomeContainerName}")
    args.container = args.mainContainer.find('.chromosome-panel.meiosis')
    args.cell = args.container.find('.cell')
    args.chromos = args.mainContainer.find('.chromosome-panel:not(.meiosis)')

    # duplicate each chromosome into sister chromatids (prophase I)
    args.chromos.find('.sister-1,.sister-2').each (i, chromo) ->
      $chromo = $(chromo)
       #$chromo.find('.alleles-container').remove()
      left = $chromo.css("left")
      if (left == "auto") then left = 0
      $chromo.css({left: left})
      # $chromo.css({left: "+=30px"})

    args.chromos.find('.sister-2').removeClass('hidden')

    @separateChromatids(args)

    # flip chromo-2 order (independent assortment) (note, this is Metaphase I and should be after crossover)
    # chromos.find('.chromo-2:not(.right)').animate({left: "+=47px"}, 200)
    # chromos.find('.chromo-2.right').animate({left: "-=47px"}, 200)
    # chromos.find('.chromo-2.right').removeClass("right").addClass("tempNotRight")
    # chromos.find('.chromo-2:not(.tempNotRight)').addClass("right")
    # chromos.find('.chromo-2.tempNotRight').removeClass("tempNotRight")
    setTimeout =>
      args.parentView.crossOver()

      # divide cell first time (Anaphase I + Telophase I)
      setTimeout =>
        @divide(args)
      , @scale(2000)
    , @scale(500)

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
          args.chromos.find(ch + sis + side).animate({left: i*30 + offset}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-Y.sister-1.right').animate({left: 376}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-Y.sister-2.right').animate({left: 406}, t, 'easeInOutQuad')
    args.cell.animate({width: 450}, t, 'easeInOutQuad')

  divide: (args)->
    # move homologous pairs apart
    # line up sister chromatids along center line (Metaphase II)
    t = @scale(400)
    args.chromos.find('.chromo-1.right').animate({top: "+=85px", left: "-=60px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-1.left').animate({top: "-=20px"}, t, 'easeInOutQuad')

    args.chromos.find('.chromo-2.right').animate({top: "+=85px", left: "-=120px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-2.left').animate({top: "-=20px", left: "-=60px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-X.right, .chromo-Y.right').animate({top: "+=85px", left: "-=180px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-X.left').animate({top: "-=20px", left: "-=120px"}, t, 'easeInOutQuad')

    # widen cell
    args.cell.animate({height: 200, width: 300}, t, 'easeInOutQuad')
    #divide cell
    setTimeout =>
      @splitCell(args)
    , t

    setTimeout =>
      @separateToGametes(args)
    , 1.75*t

  splitCell: (args)->
    t = @scale(300)
    args.container.find('.mainCell').hide()
    args.container.append($("<div class='cell cell-top'>").css({height: 200, width: 300, zIndex: -3}))
    args.container.append($("<div class='cell cell-bottom'>").css({height: 200, width: 300, zIndex: -3}))
    args.container.find('.cell-top').animate({height: 65, top: -5, width: 300}, t, 'easeInOutQuad')
    args.container.find('.cell-bottom').animate({height: 65, top: 102, width: 300}, t, 'easeInOutQuad')

  separateToGametes: (args)->
    t = @scale(1000)
    # move sisters apart to divide cell again (Anaphase II + Telophase II)
    args.chromos.find('.chromo-1.sister-1').animate({left: 10}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-2.sister-1').animate({left: 41}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-X.sister-1,.chromo-Y.sister-1').animate({left: 72}, t, 'easeInOutQuad')

    args.chromos.find('.chromo-1.sister-2').animate({left:"+=120px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-2.sister-2').animate({left:"+=73px"}, t, 'easeInOutQuad')
    args.chromos.find('.chromo-X.sister-2,.chromo-Y.sister-2').animate({left:"+=26px"}, t, 'easeInOutQuad')
    #divide cell
    @divideCell(args)

  divideCell: (args)->
    t = @scale(1000)
    args.container.find('.cell:not(.mainCell)').remove()
    args.container.append($("<div class='cell cell-left cell-top'>").css({top: -5, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-top'>").css({top: -5, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-left cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
    args.container.append($("<div class='cell cell-right cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
    args.container.find('.cell-left').animate({width:145, left: -15}, t, 'easeInOutQuad')
    args.container.find('.cell-right').animate({width:145, left: 158}, t, 'easeInOutQuad')

    setTimeout =>
      @chooseGamete(args)
    , t

  chooseGamete: (args)->
    # TODO eventually let students choose
    # container.find('.cell').click (evt)->
    #   console.log("cell click complete", evt)
    # enlarge the chosen gamete
    # and make the rest disappear
    gamete = args.parentView.get('randomGameteAnimationCell')
    chosenChromos = ""
    chosenCell = ""
    down = true
    right = true
    if gamete == 0
      chosenChromos = ".left.sister-1"
      chosenCell = ".cell-left.cell-top"
    else if gamete == 1
      chosenChromos = ".right.sister-1"
      chosenCell = ".cell-left.cell-bottom"
      down = false
    else if gamete == 2
      chosenChromos = ".left.sister-2"
      chosenCell = ".cell-right.cell-top"
      right = false
    else if gamete == 3
      chosenChromos = ".right.sister-2"
      chosenCell = ".cell-right.cell-bottom"
      down = false
      right = false
    leftShift = (if right then "+=" else "-=" ) + "88px"
    topShift = (if down then "+=" else "-=" ) + "55px"

    t = @scale(1000)

    args.chromos.find(chosenChromos).animate({left: leftShift, top: 50}, t, 'easeInOutQuad')
    args.chromos.find(".chromosome:not(" + chosenChromos + ")").animate({opacity: 0}, 0.7*t)
    args.container.find(chosenCell).animate({top: 50, left: 73}, t, 'easeInOutQuad')
    args.container.find(".cell:not(.mainCell):not(" + chosenCell + ")").animate({opacity: 0}, 0.7*t)
    setTimeout ->
      args.chromos.find(".chromosome:not(" + chosenChromos + ")").hide()
      args.container.find(".cell:not(.mainCell):not(" + chosenCell + ")").remove()
    , 0.7*t
    if args.callback?
      setTimeout ->
        args.callback()
      , 1.1*t

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

    setTimeout ->
      motherContainer.find('.cell:not(.mainCell)').hide()
    , t

    setTimeout ->
      callback()
    , 1.5*t
