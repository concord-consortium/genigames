###
  This code is currently from a spike into a meiosis animation demo, and
  is not fully integrated into the codebase. It should not be assumed that
  this code will stay here or be in this format. Currently this code does
  not randomize anything, and will not produce gametes.

  chromosomeContainerName: e.g. '#parent-fathers-pool-container'
###
GG.animateMeiosis = (chromosomeContainerName, parentView) ->
  mainContainer = $("#{chromosomeContainerName}")
  container = $('<div class="chromosome-panel meiosis" >').appendTo(mainContainer)
  cell = $('<div class="cell">').appendTo(container)
  chromos = mainContainer.find('.chromosome-panel:not(.meiosis)')

  # duplicate each chromosome into sister chromatids (prophase I)
  chromos.find('.sister-1').each (i, chromo) ->
    $chromo = $(chromo)
     #$chromo.find('.alleles-container').remove()
    left = $chromo.css("left")
    if (left == "auto") then left = 0
    $chromo.css({left: left})
    $chromo.css({left: "+=30px"})

  # separate sister chromatids
  chromos.find('.sister-1').animate({left: "-=12px"}, 800, 'easeInOutQuad')
  chromos.find('.sister-2').removeClass('hidden').animate({left: "+=12px"}, 800, 'easeInOutQuad')

  # move slightly further apart
  chromos.find('.right').animate({left: "+=20px"}, 700, 'easeInOutQuad')

  ### start crossover ###
  right = chromos.find('.chromosome.right')
  left = chromos.find('.chromosome.left')

  # move homologous pairs back closer together
  right.animate({left: "-=15px"}, 900, 'easeInOutQuad')
  left.animate({left: "+=15px"}, 900, 'easeInOutQuad')

  # flip chromo-2 order (independent assortment) (note, this is Metaphase I and should be after crossover)
  # chromos.find('.chromo-2:not(.right)').animate({left: "+=47px"}, 200)
  # chromos.find('.chromo-2.right').animate({left: "-=47px"}, 200)
  # chromos.find('.chromo-2.right').removeClass("right").addClass("tempNotRight")
  # chromos.find('.chromo-2:not(.tempNotRight)').addClass("right")
  # chromos.find('.chromo-2.tempNotRight').removeClass("tempNotRight")
  setTimeout ->
    # right = chromos.find('.chromosome.right:not(.chromo-X):not(.chromo-Y)')
    # left = chromos.find('.chromosome:not(.right):not(.chromo-X):not(.chromo-Y)')

    # duplicate each side and hide them under the other side
    # right.css({zIndex: 1}).clone().css({zIndex: -1, left: "-=47px"}).addClass('bottom').removeClass('right').appendTo(cell)
    # left.css({zIndex: 1}).clone().css({zIndex: -1, left: "+=47px"}).addClass('bottom').addClass('right').appendTo(cell)

    # hard-code crossovers for now... (note: this is still Prophase I)
    # TODO
    parentView.crossOver()
    # chromos.find('.chromo-1:not(.right).sister-1:not(.bottom)').css({height: 65})
    # chromos.find('.chromo-1.right.sister-1:not(.bottom)').css({height: 65})

    # chromos.find('.chromo-2:not(.right).sister-2:not(.bottom)').css({top: "+=20px", backgroundPositionY: -20})
    # chromos.find('.chromo-2.right.sister-1:not(.bottom)').css({top: "+=20px", backgroundPositionY: -20})

    # divide cell first time (Anaphase I + Telophase I)
    setTimeout ->
      # move homologous pairs apart
      right.animate({top: "+=175px"}, 800, 'easeInOutQuad')
      left.animate({top: "-=5px"}, 1400, 'easeInOutQuad')
      # widen cell
      cell.animate({height: 250}, 700, 'easeInOutQuad')
      #divide cell
      setTimeout ->
        container.find('.cell').remove()
        container.append($("<div class='cell cell-top'>").css({height: 250, zIndex: -3}))
        container.append($("<div class='cell cell-bottom'>").css({height: 250, zIndex: -3}))
        $('.cell-top').animate({height: 140, top: 0}, 800)
        $('.cell-bottom').animate({height: 140, top: 172}, 800)
      , 700

      # line up sister chromatids along center line (Metaphase II)
      setTimeout ->
        # separate out homologous pairs further
        # line 'em up
        left.animate({left: "+=20px"}, 400, 'easeInOutQuad')
        # chromos.find('.chromo-1').animate({top: "+=120px", left: "-=50px"}, 1600, 'easeInOutQuad')
        # chromos.find('.chromo-X,.chromo-Y').animate({top: "-=140px", left: "+=50px"}, 1700, 'easeInOutQuad')

        # move sisters apart to divide cell again (Anaphase II + Telophase II)
        setTimeout ->
          chromos.find('.chromo-1.sister-1').animate({left:"-=55px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-2.sister-1').animate({left:"-=108px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-X.sister-1,.chromo-Y.sister-1').animate({left:"-=160px"}, 2200, 'easeInOutQuad')

          chromos.find('.chromo-1.sister-2').animate({left:"+=127px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-2.sister-2').animate({left:"+=80px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-X.sister-2,.chromo-Y.sister-2').animate({left:"+=30px"}, 2200, 'easeInOutQuad')
          #divide cell
          setTimeout ->
            container.find('.cell').remove()
            container.append($("<div class='cell cell-left cell-top'>").css({top: 0, height: 140, zIndex: -2}))
            container.append($("<div class='cell cell-right cell-top'>").css({top: 0, height: 140, zIndex: -2}))
            container.append($("<div class='cell cell-left cell-bottom'>").css({top: 172, height: 140, zIndex: -2}))
            container.append($("<div class='cell cell-right cell-bottom'>").css({top: 172, height: 140, zIndex: -2}))
            container.find('.cell-left').animate({width:175}, 800)
            container.find('.cell-right').animate({width:175, left: 130}, 800)
            # TODO eventually let students choose
            # $('.cell').click (evt)->
            #   console.log("cell click complete", evt)
            # enlarge the chosen gamete
            # and make the rest disappear
            gamete = parentView.get('randomGameteNumber')
            console.log("chose gamete: " + gamete)
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
            console.log("chosen chromos: ", chosenChromos)
            console.log("chosen cell: ", chosenCell)
            leftShift = (if right then "+=" else "-=" ) + "80px"
            topShift = (if down then "+=" else "-=" ) + "70px"
            chromos.find(chosenChromos).animate({left: leftShift, top: topShift}, 2000)
            chromos.find(".chromosome:not(" + chosenChromos + ")").animate({opacity: 0}, 1500)
            container.find(chosenCell).animate({top: 85, left: 65}, 2000)
            container.find(".cell:not(" + chosenCell + ")").animate({opacity: 0}, 1500)
            setTimeout ->
              chromos.find(".chromosome:not(" + chosenChromos + ")").remove()
              container.find(".cell:not(" + chosenCell + ")").remove()
            , 1500
          , 1100
        , 2500
      , 2000
    , 1500
  , 3500

###
  Again, not in the right place, add a click handler to remove animation from screen
###
GG.meiosisIsComplete = false
