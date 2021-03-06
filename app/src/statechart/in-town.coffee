GG.StateInTown = Ember.State.extend

  initialState: 'npcsWaiting'
  justCompletedTask: null
  lastSuccess: null

  setup: (manager, context) ->
    if context?
      @set 'justCompletedTask', context[0]
      @set 'lastSuccess', context[1]
    else
      @set 'justCompletedTask', null
      @set 'lastSuccess', null

  enter: (manager) ->
    GG.universeView.setCurrentView 'town'
    GG.hideInfoDialogs()
    manager.send 'hideLeaderboard'
    $('#town').fadeIn(1000)

  exit: (manager) ->
    GG.hideInfoDialogs()
    manager.send 'hideLeaderboard'
    $('#town').fadeOut(1000)

  goToWorld: (manager) ->
    manager.transitionTo 'inWorld'

  npcsWaiting: Ember.State.create

    # we use setup instead of enter because otherwise the variable justCompletedTask
    # will not have been set yet. Note: "setup" method name may change in later v's of Ember
    setup: (manager) ->
      GG.tasksController.clearCurrentTask()
      manager.send 'hideLeaderboard'
      task.set('showQuestionBubble', false) for task in GG.tasksController.content
      task.set('showSpeechBubble', false) for task in GG.tasksController.content

      firstIncompleteTask_i = -1
      lastCompleteTask_i = -1
      finishedAllTasks = false
      for task, i in GG.tasksController.content
        foregroundLocation = if (i%2) then "right" else "left"
        task.set('foregroundLocation', foregroundLocation)
        task.set('showInForeground', false)
        complete = task.get('completed')
        lastCompleteTask_i = i if complete
        firstIncompleteTask_i = i unless complete or (firstIncompleteTask_i > -1)

      if firstIncompleteTask_i > -1
        firstIncompleteTask = GG.tasksController.content[firstIncompleteTask_i]
      else
        firstIncompleteTask_i = GG.tasksController.content.length-1
        lastCompleteTask_i = firstIncompleteTask_i - 1
        finishedAllTasks = true

      GG.tasksController.content[firstIncompleteTask_i].set('showInForeground', true)

      justCompletedTask = @get 'parentState.justCompletedTask'
      lastSuccess = @get 'parentState.lastSuccess'

      justCompletedAnEarlierTask = justCompletedTask? and
        (justCompletedTask isnt GG.tasksController.content[lastCompleteTask_i]) and
        (justCompletedTask isnt GG.tasksController.content[firstIncompleteTask_i])

      if justCompletedTask? and justCompletedAnEarlierTask
        otherTaskLocation = GG.tasksController.content[firstIncompleteTask_i].get('foregroundLocation')
        justCompletedTask.set('foregroundLocation', (if otherTaskLocation is "right" then "left" else "right"))
        justCompletedTask.set('showInForeground', true)
      else
        GG.tasksController.content[lastCompleteTask_i].set('showInForeground', true) unless (lastCompleteTask_i < 0)

      if justCompletedTask? and (lastSuccess == true) and (justCompletedTask is GG.tasksController.content[lastCompleteTask_i]) and (!finishedAllTasks)
        setTimeout =>
          manager.transitionTo 'npcsShowingTaskEndMessage'
          GG.tasksController.showTaskEndMessage justCompletedTask
        , 50
      else if justCompletedTask? and (lastSuccess == true) and justCompletedAnEarlierTask
        setTimeout =>
          manager.transitionTo 'npcsShowingTaskEndMessage'
          GG.tasksController.showTaskThanksMessage justCompletedTask
        , 50
      else if justCompletedTask? and (lastSuccess == false)
        setTimeout =>
          manager.transitionTo 'npcsShowingTaskEndMessage'
          GG.tasksController.showTaskFailMessage justCompletedTask
        , 50
      else if firstIncompleteTask?
        setTimeout =>
          firstIncompleteTask.set 'isShowingFailMessage', false
          firstIncompleteTask.set 'isShowingEndMessage', false
          firstIncompleteTask.set 'isShowingThanksMessage', false
          firstIncompleteTask.set 'showQuestionBubble', true
        , 1000
      else if justCompletedTask and !justCompletedAnEarlierTask
        GG.townsController.completeCurrentTown()
        setTimeout =>
          manager.transitionTo 'npcShowingFinalMessage'
        , 1000

      setTimeout =>
        GG.tasksController.updateHeartFills()
      , 100


    npcSelected: (manager, task) ->
      GG.tasksController.showTaskDescription task
      GG.statemanager.transitionTo 'npcShowingTask'

    replayTask: (manager, task) ->
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task

  npcsShowingTaskEndMessage: Ember.State.create
    replay: (manager, task) ->
      GG.tasksController.setCurrentTask task, true
      GG.tasksController.restartCurrentTask()
    done: (manager) ->
      @get('parentState').set('lastSuccess', null)
      manager.transitionTo 'npcsWaiting'

  npcShowingTask: Ember.State.create
    accept: (manager, task) ->
      manager.send 'hideLeaderboard'
      GG.tasksController.taskAccepted task
    decline: (manager) ->
      manager.transitionTo 'npcsWaiting'

    replayTask: (manager, task) ->
      # do nothing

  npcShowingFinalMessage: Ember.State.create
    enter: ->
      lastTask = GG.tasksController.get("lastObject")
      lastTask.set('showFinalMessageBubble', true)

    replayTask: (manager, task) ->
      lastTask = GG.tasksController.get("lastObject")
      lastTask.set('showFinalMessageBubble', false)
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task

    showEndAnimation: (manager) ->
      lastTask = GG.tasksController.get("lastObject")
      lastTask.set('showFinalMessageBubble', false)
      manager.transitionTo 'showingEndAnimation'

  showingEndAnimation: Ember.State.create
    enter: ->
      $(".npc, .gradient").fadeOut(1000)
      $("#finalAnimation").fadeIn(1000)
      setTimeout ->
        $("#topBar, #town").fadeOut(1500)
      , 2500

      window.flashAnimationComplete = ->
        $(".flash-buttons").fadeIn(2000)

    replay: ->
      $(".flash-buttons").fadeOut()
      document.getElementById('completionAnimation17-flash').replayFlashAnimation()


