GG.StateInTown = Ember.State.extend

  initialState: 'npcsWaiting'

  enter: ->
    GG.universeView.setCurrentView 'town'

  npcsWaiting: Ember.State.create
    enter: (manager) ->
      GG.tasksController.set 'upcomingTask', null
      GG.tasksController.set 'currentTask', null
      task.set('showQuestionBubble', false) for task in GG.tasksController.content
      task.set('showSpeechBubble', false) for task in GG.tasksController.content

      firstIncompleteTask = null
      for task in GG.tasksController.content
        firstIncompleteTask = task unless task.get('completed') or firstIncompleteTask?

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

  npcShowingTask: Ember.State.create
    accept: (manager, task) ->
      GG.tasksController.taskAccepted task
    decline: (manager) ->
      manager.transitionTo 'npcsWaiting'

  npcShowingFinalMessage: Ember.State.create
    enter: ->
      lastTask = GG.tasksController.get("lastObject")
      lastTask.set('showFinalMessageBubble', true)
