GG.StateInTaskList = Ember.State.extend

  initialState: 'tasksAvailable'

  enter: ->
    $('#task-list').fadeIn(1000)

  exit: ->
    $('#task-list').fadeOut(1000)

  tasksAvailable: Ember.State.create
    enter: (manager) ->
      GG.tasksController.clearCurrentTask()

      firstIncompleteTask = null
      for task in GG.tasksController.content
        firstIncompleteTask = task unless task.get('completed') or firstIncompleteTask?

      unless firstIncompleteTask?
        GG.townsController.completeCurrentTown()
        setTimeout =>
          manager.transitionTo 'tasksCompleted'
        , 1000

    taskSelected: (manager, task) ->
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task

  tasksCompleted: Ember.State.create
    enter: ->
      $('#tasks-completed').fadeIn(1000)

    taskSelected: (manager, task) ->
      GG.tasksController.setCurrentTask task
      GG.tasksController.taskAccepted task
