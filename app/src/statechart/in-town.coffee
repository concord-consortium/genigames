GG.StateInTown = Ember.State.extend

  initialState: 'npcsWaiting'

  enter: ->
    GG.universeView.setCurrentView 'town'
    $('#town').fadeIn(1000)

  exit: ->
    $('#town').fadeOut(1000)

  npcsWaiting: Ember.State.create
    enter: (manager) ->
      GG.tasksController.clearCurrentTask()
      task.set('showQuestionBubble', false) for task in GG.tasksController.content
      task.set('showSpeechBubble', false) for task in GG.tasksController.content

      firstIncompleteTask_i = -1
      lastCompleteTask_i = -1
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

      GG.tasksController.content[firstIncompleteTask_i].set('showInForeground', true)
      GG.tasksController.content[lastCompleteTask_i].set('showInForeground', true) unless (lastCompleteTask_i < 0)



      # Go to world view if all tasks are complete?
      # TODO Add some sort of transition with dialog
      if firstIncompleteTask?
        setTimeout =>
          firstIncompleteTask.set('showQuestionBubble', true)
        , 1000
      else
        GG.townsController.completeCurrentTown()
        setTimeout =>
          manager.transitionTo 'npcShowingFinalMessage'
        , 1000


    npcSelected: (manager, task) ->
      GG.tasksController.showTaskDescription task
      GG.statemanager.transitionTo 'npcShowingTask'

    replayTask: (manager, task) ->
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task

  npcShowingTask: Ember.State.create
    accept: (manager, task) ->
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
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task
