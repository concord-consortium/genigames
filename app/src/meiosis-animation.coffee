###
  This code is currently from a spike into a meiosis animation demo, and
  is not fully integrated into the codebase. It should not be assumed that
  this code will stay here or be in this format. Currently this code does
  not randomize anything, and will not produce gametes.

  chromosomeContainerName: e.g. '#parent-fathers-pool-container'
###
GG.animateMeiosis = (chromosomeContainerName) ->
  container = $("#{chromosomeContainerName} .chromosome-panel")
  cell = $('<div class="cell">').appendTo(container)
  chromosomes = container.find('.chromosome')

  # duplicate each chromosome into sister chromatids (prophase I)
  chromosomes.each (i, chromo) ->
    $chromo = $(chromo)
    $chromo.find('.alleles-container').remove()
    left = $chromo.css("left")
    if (left == "auto") then left = 0
    $chromo.css({left: left})
    $chromo.css({left: "+=70px"})
    $chromo.appendTo(cell)
    sisterChromatid = $chromo.clone().addClass('sister-2').appendTo(cell)
    $chromo.addClass('sister-1')

  # separate sister chromatids
  cell.find('.sister-1').animate({left: "-=12px"}, 800, 'easeInOutQuad')
  cell.find('.sister-2').animate({left: "+=12px"}, 800, 'easeInOutQuad')

  # move slightly further apart
  cell.find('.right').animate({left: "+=20px"}, 700, 'easeInOutQuad')

  ### start crossover ###
  right = cell.find('.chromosome.right')
  left = cell.find('.chromosome:not(.right)')

  # move homologous pairs back closer together
  right.animate({left: "-=15px"}, 900, 'easeInOutQuad')
  left.animate({left: "+=15px"}, 900, 'easeInOutQuad')

  # flip chromo-2 order (independent assortment) (note, this is Metaphase I and should be after crossover)
  cell.find('.chromo-2:not(.right)').animate({left: "+=47px"}, 200)
  cell.find('.chromo-2.right').animate({left: "-=47px"}, 200)
  cell.find('.chromo-2.right').removeClass("right").addClass("tempNotRight")
  cell.find('.chromo-2:not(.tempNotRight)').addClass("right")
  cell.find('.chromo-2.tempNotRight').removeClass("tempNotRight")
  setTimeout ->
    right = cell.find('.chromosome.right:not(.chromo-X):not(.chromo-Y)')
    left = cell.find('.chromosome:not(.right):not(.chromo-X):not(.chromo-Y)')

    # duplicate each side and hide them under the other side
    right.css({zIndex: 1}).clone().css({zIndex: -1, left: "-=47px"}).addClass('bottom').removeClass('right').appendTo(cell)
    left.css({zIndex: 1}).clone().css({zIndex: -1, left: "+=47px"}).addClass('bottom').addClass('right').appendTo(cell)

    # hard-code crossovers for now... (note: this is still Prophase I)
    cell.find('.chromo-1:not(.right).sister-1:not(.bottom)').css({height: 65})
    cell.find('.chromo-1.right.sister-1:not(.bottom)').css({height: 65})

    cell.find('.chromo-2:not(.right).sister-2:not(.bottom)').css({top: "+=20px", backgroundPositionY: -20})
    cell.find('.chromo-2.right.sister-1:not(.bottom)').css({top: "+=20px", backgroundPositionY: -20})

    # divide cell first time (Anaphase I + Telophase I)
    setTimeout ->
      # move homologous pairs apart
      cell.find('.right').animate({left: "+=165px"}, 800, 'easeInOutQuad')
      cell.find(':not(.right)').animate({left: "-=5px"}, 1400, 'easeInOutQuad')
      # widen cell
      cell.animate({width: 400, left: -120}, 700, 'easeInOutQuad')
      #divide cell
      setTimeout ->
        cell.css({backgroundColor: "transparent"})
        container.append($("<div class='cell cell-left'>").css({top: -19, left: -121, zIndex: 1}))
        container.append($("<div class='cell cell-right'>").css({top: -19, left: 30, zIndex: 1}))
        $('.cell-left').animate({width: 188}, 800)
        $('.cell-right').animate({width: 188, left: 78}, 800)
      , 700

      # line up sister chromatids along center line (Metaphase II)
      setTimeout ->
        # separate out homologous pairs further
        # line 'em up
        cell.find('.chromo-1').animate({top: "+=120px", left: "-=50px"}, 1600, 'easeInOutQuad')
        cell.find('.chromo-X,.chromo-Y').animate({top: "-=140px", left: "+=50px"}, 1700, 'easeInOutQuad')

        # move sisters apart to divide cell again (Anaphase II + Telophase II)
        setTimeout ->
          cell.find('.chromo-1.sister-1').animate({top:"-=110px", left:"+=20px"}, 2200, 'easeInOutQuad')
          cell.find('.chromo-2.sister-1').animate({top:"-=100px"}, 2200, 'easeInOutQuad')
          cell.find('.chromo-X.sister-1,.chromo-Y.sister-1').animate({top:"-=110px", left:"-=20px"}, 2200, 'easeInOutQuad')

          cell.find('.chromo-1.sister-2').animate({top:"+=110px", left:"-=10px"}, 2200, 'easeInOutQuad')
          cell.find('.chromo-2.sister-2').animate({top:"+=100px", left:"-=20px"}, 2200, 'easeInOutQuad')
          cell.find('.chromo-X.sister-2,.chromo-Y.sister-2').animate({top:"+=90px", left:"-=40px"}, 2200, 'easeInOutQuad')
          #divide cell
          setTimeout ->
            $('.cell').css({backgroundColor: "transparent"})
            container.append($("<div class='cell cell-left cell-top'>").css({top: -19, left: -121, width: 188, height: 260, zIndex: 1}))
            container.append($("<div class='cell cell-right cell-top'>").css({top: -19, left: 78, width: 188, height: 260, zIndex: 1}))
            container.append($("<div class='cell cell-left cell-bottom'>").css({top: 140, left: -121, width: 188, height: 260, zIndex: 1}))
            container.append($("<div class='cell cell-right cell-bottom'>").css({top: 140, left: 78, width: 188, height: 260, zIndex: 1}))
            $('.cell-top').animate({height:190}, 800)
            $('.cell-bottom').animate({height:190, top: 210}, 800)
            GG.meiosisIsComplete = true
          , 1100
        , 2500
      , 2000
    , 1500
  , 3500

###
  Again, not in the right place, add a click handler to remove animation from screen
###
GG.meiosisIsComplete = false
$('body').click ->
  if GG.meiosisIsComplete
    GG.meiosisIsComplete = false
    $('.cell').remove()
    # hack: remove parents and replace to re-populate chromosomes
    mother = GG.breedingController.get 'mother'
    father = GG.breedingController.get 'father'
    Ember.run ->
      GG.breedingController.set 'mother', null
      GG.breedingController.set 'father', null
    Ember.run ->
      GG.breedingController.set 'mother', mother
      GG.breedingController.set 'father', father
