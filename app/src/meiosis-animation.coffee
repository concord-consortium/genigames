###
  This code is currently from a spike into a meiosis animation demo, and
  is not fully integrated into the codebase. It should not be assumed that
  this code will stay here or be in this format. Currently this code does
  not randomize anything, and will not produce gametes.

  chromosomeContainerName: e.g. '#parent-fathers-pool-container'
###
GG.resetAnimation = (chromosomeContainerName) ->
  mainContainer = $("#{chromosomeContainerName}")
  mainContainer.find(".chromosome-panel.meiosis").remove()
  mainContainer.find(".chromosome").css({opacity: 1, width: "", height: "", top: "", left: ""})
  mainContainer.find(".chromosome").show()

GG.animateMeiosis = (chromosomeContainerName, parentView, callback) ->
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
    # $chromo.css({left: "+=30px"})

  # separate sister chromatids
  chromos.find('.sister-1').animate({left: "+=18px"}, 800, 'easeInOutQuad')
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
    parentView.crossOver()

    # divide cell first time (Anaphase I + Telophase I)
    setTimeout ->
      # move homologous pairs apart
      right.animate({top: "+=85px", left: "-=20px"}, 800, 'easeInOutQuad')
      left.animate({top: "-=20px"}, 1400, 'easeInOutQuad')
      # widen cell
      cell.animate({height: 200}, 700, 'easeInOutQuad')
      #divide cell
      setTimeout ->
        container.find('.cell').remove()
        container.append($("<div class='cell cell-top'>").css({height: 200, zIndex: -3}))
        container.append($("<div class='cell cell-bottom'>").css({height: 200, zIndex: -3}))
        $('.cell-top').animate({height: 65, top: -5}, 800)
        $('.cell-bottom').animate({height: 65, top: 102}, 800)
      , 700

      # line up sister chromatids along center line (Metaphase II)
      setTimeout ->
        # move sisters apart to divide cell again (Anaphase II + Telophase II)
        setTimeout ->
          chromos.find('.chromo-1.sister-1').animate({left:"-=50px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-2.sister-1').animate({left:"-=100px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-X.sister-1,.chromo-Y.sister-1').animate({left:"-=150px"}, 2200, 'easeInOutQuad')

          chromos.find('.chromo-1.sister-2').animate({left:"+=124px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-2.sister-2').animate({left:"+=77px"}, 2200, 'easeInOutQuad')
          chromos.find('.chromo-X.sister-2,.chromo-Y.sister-2').animate({left:"+=30px"}, 2200, 'easeInOutQuad')
          #divide cell
          setTimeout ->
            container.find('.cell').remove()
            container.append($("<div class='cell cell-left cell-top'>").css({top: -5, height: 65, zIndex: -2}))
            container.append($("<div class='cell cell-right cell-top'>").css({top: -5, height: 65, zIndex: -2}))
            container.append($("<div class='cell cell-left cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
            container.append($("<div class='cell cell-right cell-bottom'>").css({top: 100, height: 65, zIndex: -2}))
            container.find('.cell-left').animate({width:145, left: -15}, 800, 'easeInOutQuad')
            container.find('.cell-right').animate({width:145, left: 158}, 800, 'easeInOutQuad')

            # TODO eventually let students choose
            # $('.cell').click (evt)->
            #   console.log("cell click complete", evt)
            # enlarge the chosen gamete
            # and make the rest disappear
            gamete = parentView.get('randomGameteNumber')
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
            setTimeout ->
              chromos.find(chosenChromos).animate({left: leftShift, top: topShift}, 2000, 'easeInOutQuad')
              chromos.find(".chromosome:not(" + chosenChromos + ")").animate({opacity: 0}, 1500)
              container.find(chosenCell).animate({top: 50, left: 73}, 2000, 'easeInOutQuad')
              container.find(".cell:not(" + chosenCell + ")").animate({opacity: 0}, 1500)
              setTimeout ->
                chromos.find(".chromosome:not(" + chosenChromos + ")").hide()
                container.find(".cell:not(" + chosenCell + ")").remove()
              , 1500
              if callback?
                setTimeout ->
                  callback()
                , 3000
            , 2000
          , 1100
        , 2500
      , 2000
    , 1500
  , 3500

###
  Again, not in the right place, add a click handler to remove animation from screen
###
GG.meiosisIsComplete = false
