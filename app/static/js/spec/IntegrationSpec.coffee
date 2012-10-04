describe "A student", ->

  vars = {}
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

  beforeEach ->
    $('#container').show()

  afterEach ->
    $('#container').hide()

  # The scenario so far:
  #   starting at the world
  #   click on the first town
  #   click on the first npc task bubble
  #   accept the task
  #   manipulate the breeding machine
  #   complete the task
  #   click on the second npc task bubble
  #   click maybe later
  #   click on the second npc task bubble
  #   accept the task
  #   complete the task
  #   click on the second town
  #   verify tasks are available

  it "should start with zero reputation", ->
    runAndWait "Pause", 1000, ->
      console.log 'waiting for load'
    , ->
      expect(GG.userController.get('user.reputation')).toBe(0)

  it "should be able to click on the first town", ->
    expect(GG.townsController.get('currentTown')).toBe(null)
    expect($('#world').length).toBe(1)
    expect($('.castle').length).toBe(1)

    runAndWait "Castle should be clicked", 3000, ->
      Ember.run ->
        $('.castle').click()
    , ->
      expect($('#world').length).toBe(0)
      expect($('.castle').length).toBe(0)
      expect($('#town').length).toBe(1)
      expect(GG.townsController.get('currentTown')).toBe(GG.townsController.get('content')[0])

  it "should see the npc and bubble", ->
    expect($('.npc').length).toBeGreaterThan(0)
    expect($('.npc .bubble').length).toBeGreaterThan(0)

  it "should be able to click the bubble", ->
    runAndWait "Question bubble should be clicked", 200, ->
      Ember.run ->
        $('.npc a img:not(.hidden)').click()
    , ->
      expect($('.npc a img:not(.hidden)').length).toBe(0)
      expect($('.npc .speech-bubble:not(.hidden)').length).toBe(1)

  it "should be able to accept the task, and the breeding view slides in", ->
    expect($('.npc .speech-bubble:not(.hidden) button:contains("Ok")').length).toBe(1)
    expect(parseInt($('#breeding-apparatus').css('left'))).toBeGreaterThan(1000)
    runAndWait "Task should be accepted, breeding machine should load", 400, ->
      Ember.run ->
        $('.npc .speech-bubble:not(.hidden) button:contains("Ok")')[0].click()
    , ->
      expect($('.npc .speech-bubble:not(.hidden)').length).toBe(0)
      expect($('.heart-bubble:not(.hidden)').length).toBe(0)
      expect($('.npc a img:not(.hidden)').length).toBe(0)
      expect(parseInt($('#breeding-apparatus').css('left'))).toBeLessThan(1000)
      expect(GG.tasksController.get('currentTask')).toBe(GG.tasksController.get('content')[0])
      expect(GG.parentController.get('selectedMother')).toBe(null)
      expect(GG.parentController.get('selectedFather')).toBe(null)
      expect(GG.parentController.get('content').length).toBe(4)
      expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1)
      expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1)
      expect(GG.breedingController.get('child')).toBe(null)
      expect(GG.cyclesController.get('cycles')).toBe(10)

  it "should not see chromosome panels", ->
    expect($('#parent-fathers-pool-container .chromosome-panel.hidden').length).toBe(1)
    expect($('#parent-mothers-pool-container .chromosome-panel.hidden').length).toBe(1)

  it "should see a disabled breed button", ->
    expect($('#breed-button:not(.enabled)').length).toBe(1)

  it "should be able to select parents", ->
    runAndWait "Mother should be selectable", 500, ->
      Ember.run ->
        parents = $('#parent-mothers-pool-container .parent a')
        expect(parents.length).toBe(2)
        parents[0].click()
    , ->
      expect(GG.parentController.get('selectedMother')).toNotBe(null)
      expect($('#breed-button.enabled').length).toBe(0)

    runAndWait "Father should be selectable", 500, ->
      Ember.run ->
        parents = $('#parent-fathers-pool-container .parent a')
        expect(parents.length).toBe(2)
        parents[0].click()
    , ->
      expect(GG.parentController.get('selectedFather')).toNotBe(null)
      expect($('#breed-button.enabled').length).toBe(1)

  it "should see chromosome panels", ->
    expect($('#parent-fathers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1)
    expect($('#parent-mothers-pool-container .chromosome-panel:not(.hidden)').length).toBe(1)

  it "should see an enabled breed button", ->
    expect($('#breed-button.enabled').length).toBe(1)

  it "should be able to breed the two parents and get an offspring", ->
    runAndWait "Breeding should be successful", 2000, ->
      Ember.run ->
        $('#breed-button.enabled')[0].click()
    , ->
      expect(GG.breedingController.get('child')).toNotBe(null)
      expect(GG.offspringController.get('content')).toNotBe(null)

  it "should see that cycles has decreased to 9", ->
    expect(GG.cyclesController.get('cycles')).toBe(9)

  it "should be able to breed again and decrease cycles to 8", ->
    runAndWait "Breed", 2000, ->
      Ember.run ->
        $('#breed-button.enabled')[0].click()
    , ->
      expect(GG.cyclesController.get('cycles')).toBe(8)

  it "should be able to move offspring to parent pool", ->
    vars.offspringSex = null
    runAndWait "Offspring can be moved to the parent pool", 200, ->
      vars.offspringSex = GG.breedingController.getPath('child.sex')
      $('.offspring-buttons-save').click()
    , ->
      expect(GG.parentController.get('content').length).toBe(5)
      expect(GG.offspringController.get('content')).toBe(null)
      pool = if vars.offspringSex == GG.MALE then "#parent-fathers-pool-container" else "#parent-mothers-pool-container"
      newParents = $(pool + ' .parent a:not(.removeButton)')
      expect(newParents.length).toBe(3)

  it "should decrease reputation to -1", ->
    expect(GG.userController.get('user.reputation')).toBe(-1)

  it "should be able to select offspring and breed with it", ->
    runAndWait "Go back to select parents", 800, ->
      $('.select-parents').click()
    , ->
      runAndWait "Offspring can be used to breed", 2000, ->
        console.log vars.offspringSex
        pool = if vars.offspringSex == GG.MALE then "#parent-fathers-pool-container" else "#parent-mothers-pool-container"
        console.log pool
        # click the third drake in the pool
        $(pool + " .parent a")[2].click()
        $('#breed-button').click()
      , ->
        expect(GG.breedingController.get('child')).toNotBe(null)
        expect(GG.offspringController.get('content')).toNotBe(null)
        expect(GG.cyclesController.get('cycles')).toBe(7)

  it "should get a reject message if they submit an incorrect drake", ->
    expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(0)
    vars.offspringHasWings = GG.breedingController.get('child').get("biologicaOrganism").getCharacteristic("wings") == "Wings"
    impossibleTask = if vars.offspringHasWings then "no wings" else "wings"
    GG.tasksController.set('currentTask.targetDrake', impossibleTask)
    runAndWait "Submit offspring", 200, ->
      $('.offspring-buttons-use').click()
    , ->
      expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(1)
      speechText = $('.speech-bubble-no-npc:not(.hidden)').html()
      successText = GG.tasksController.get('currentTask.npc.speech.completionText').replace(/<br\/>/g,"<br>")
      expect(speechText.indexOf(successText)).toBe(-1)

  it "should get a success message if they submit a correct drake", ->
    runAndWait "Click ok", 200, ->
      $('.speech-bubble-no-npc:not(.hidden) button').click()
    , ->
      expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(0)
      vars.offspringHasWings = GG.breedingController.get('child').get("biologicaOrganism").getCharacteristic("wings") == "Wings"
      possibleTask = if vars.offspringHasWings then "wings" else "no wings"
      GG.tasksController.set('currentTask.targetDrake', possibleTask)
      runAndWait "Submit offspring", 200, ->
        $('.offspring-buttons-use').click()
      , ->
        expect($('.speech-bubble-no-npc:not(.hidden)').length).toBe(1)
        speechText = $('.speech-bubble-no-npc:not(.hidden)').html()
        successText = GG.tasksController.get('currentTask.npc.speech.completionText').replace(/<br\/>/g,"<br>")
        expect(speechText.indexOf(successText)).toBeGreaterThan(0)

  it "should go back to the town after they dismiss the success message", ->
    expect($('.npc .bubble:not(.hidden)').length).toBe(0)
    runAndWait "Click ok", 1500, ->
      $('.speech-bubble-no-npc:not(.hidden) button').click()
    , ->
      expect(parseInt($('#breeding-apparatus').css('left'))).toBeGreaterThan(1000)
      expect($('.npc .bubble:not(.hidden)').length).toBe(1)
