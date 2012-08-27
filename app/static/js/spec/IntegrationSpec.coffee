describe "Integration", ->

  flag = false
  runAndWait = (msg, time, action, result) ->
    runs ->
      flag = false
      action()
      setTimeout ->
        flag = true
      , time

    waitsFor ->
      flag
    , (time+100)

    if result?
      runs ->
        result()

  # The scenario so far:
  #   starting at the world
  #   click on the first town
  #   click on the first npc task bubble
  #   accept the task
  #   manipulate the breeding machine
  #   TODO complete the task
  #   TODO click on the second npc task bubble
  #   TODO click maybe later
  #   TODO click on the second npc task bubble
  #   TODO accept the task
  #   TODO complete the task
  #   TODO click on the second town
  #   TODO verify tasks are available

  it "should be able to behave like a student", ->
    @after ->
      console.log "running after"
      $('#container').hide()

    runAndWait "Pause", 1000, ->
      console.log 'waiting for load'
    , ->
      expect(GG.townsController.get('currentTown')).toBe(null)

    runAndWait "Castle should be clicked", 5000, ->
      Ember.run ->
        $('.castle').click()
    , ->
      expect(GG.townsController.get('currentTown')).toBe(GG.townsController.get('content')[0])

    runAndWait "Question bubble should be clicked", 200, ->
      Ember.run ->
        $('.npc a img:not(.hidden)').click()
    , ->
      expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1)

    runAndWait "Task should be accepted, breeding machine should load", 3000, ->
      Ember.run ->
        $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click()
    , ->
      expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0)
      expect($('.npc a img:not(.hidden)').length).toBe(0)
      expect($('#breed-button.enabled').length).toBe(0)
      expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[0])
      expect(GG.parentController.get('selectedMother')).toBe(null)
      expect(GG.parentController.get('selectedFather')).toBe(null)
      expect(GG.parentController.get('content').length).toBe(4)
      expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1)
      expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1)
      expect(GG.breedingController.get('child')).toBe(null)

    runAndWait "Mother should be selectable", 500, ->
      Ember.run ->
        parents = $('#parent-mothers-pool-container .parent img')
        expect(parents.length).toBe(2)
        parents[0].click()
    , ->
      expect(GG.parentController.get('selectedMother')).toNotBe(null)
      expect($('#breed-button.enabled').length).toBe(0)

    runAndWait "Father should be selectable", 500, ->
      Ember.run ->
        parents = $('#parent-fathers-pool-container .parent img')
        expect(parents.length).toBe(2)
        parents[0].click()
    , ->
      expect(GG.parentController.get('selectedFather')).toNotBe(null)
      expect($('#breed-button.enabled').length).toBe(1)

    # chromosome panels should expand
    runAndWait "Chromosome panels should be expandable", 2200, ->
      Ember.run ->
        for ex in $('.expander')
          ex.click()
    , ->
      expect($('#parent-fathers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1)
      expect($('#parent-mothers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1)

    # TODO changing selected parent should change chromosomes

    # chromosome panels should collapse
    runAndWait "Chromosome panels should be collapsible", 2200, ->
      Ember.run ->
        for ex in $('.expander')
          ex.click()
    , ->
      expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1)
      expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1)

    # breed
    runAndWait "Breeding should be successful", 2000, ->
      Ember.run ->
        $('#breed-button.enabled')[0].click()
    , ->
      expect(GG.breedingController.get('child')).toNotBe(null)
      expect(GG.offspringController.get('content').length).toBe(1)
      expect(GG.moveController.get('moves')).toBe(1)

    # put offspring into parent pool
    offspringParentSex = null
    runAndWait "Offspring can be moved to the parent pool", 400, ->
      offspringParentSex = GG.breedingController.getPath('child.sex')
      $('#offspring-pool .offspring img').click()
    , ->
      expect(GG.parentController.get('content').length).toBe(5)
      expect(GG.offspringController.get('content').length).toBe(0)
      expect(GG.moveController.get('moves')).toBe(2)


    # breed with offspring
    pool = ""
    runAndWait "Offspring can be used to breed", 2000, ->
      pool = if offspringParentSex == GG.MALE then "#parent-fathers-pool-container" else "#parent-mothers-pool-container"
      # click the third drake in the pool
      $(pool + " .parent img")[2].click()
      $('#breed-button').click()
    , ->
      expect(GG.breedingController.get('child')).toNotBe(null)
      expect(GG.offspringController.get('content').length).toBe(1)
      expect(GG.moveController.get('moves')).toBe(3)

    # TODO Not sure how to make this work?
    #runAndWait "Offspring get delete icon that shows on hover", 100, ->
      ## click the third drake in the pool
      #expect($(pool + " .parent .removeButton").css('display')).toBe('none')
      #$(pool + " .parent a").closest('.parent').trigger('mouseover')
    #, ->
      #expect($(pool + " .parent .removeButton").css('display')).toBe('inline')

    #runAndWait "Offspring get delete icon that disappears when mouse leaves", 100, ->
      ## click the third drake in the pool
      #expect($(pool + " .parent .removeButton").css('display')).toBe('inline')
      #$(pool + " .parent  img~a").closet('.parent').trigger('mouseout')
    #, ->
      #expect($(pool + " .parent .removeButton").css('display')).toBe('none')

    # remove offspring from parent pool
    runAndWait "Offspring parent can be removed from the parent pool", 200, ->
      $(pool + " .parent .removeButton").click()
    , ->
      expect(GG.parentController.get('content').length).toBe(4)
      sel = if offspringParentSex == GG.MALE then 'selectedFather' else 'selectedMother'
      expect(GG.parentController.get(sel)).toBe(null)
      expect($(pool + " .parent .removeButton").length).toBe(0)

    # FIXME Not sure how to repeat an action until we see a certain outcome...
    # stub this for now
    runs ->
      flag = false
      # game currently wants wingless. Add B to avoid dead drakes.
      GenGWT.generateAliveDragonWithAlleleStringAndSex "a:w,b:w,a:B", GG.FEMALE, (org) ->
        drake = GG.Drake.createFromBiologicaOrganism org
        Ember.run ->
          GG.parentController.pushObject drake
          GG.parentController.selectMother drake
        GenGWT.generateAliveDragonWithAlleleStringAndSex "a:w,b:w,a:B", GG.MALE, (org) ->
          drake = GG.Drake.createFromBiologicaOrganism org
          Ember.run ->
            GG.parentController.pushObject drake
            GG.parentController.selectFather drake
          GG.breedingController.breedDrake()
          setTimeout ->
            flag = true
          , 3000

    waitsFor ->
      flag
    , "Should (stubbed out) breed the correct drake", 5500

    runAndWait "Click ok to complete the task", 3000, ->
      # the npc's success bubble should be showing
      expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1)
      # can click ok
      $('.npc .speech-bubble:not(.hidden) button:contains("Ok")').click()
    , ->
      # check for the heart bubble
      # other NPC bubbles should be closed
      # the next NPC's question bubble should be showing
      # breeder should be gone
      # breeder wings should be closed

      expect(true).toBe(true)
