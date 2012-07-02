GG.Animation = Ember.Mixin.create

  # by default, this will animate the view's outer element
  # set this if you want a different element to be the default
  # animation element.
  topLevelCssElement: null

  duration: 1000

  easing: 'swing'

  # set this to cause something to happen when the view becomes visible
  onShow: null

  wasShown: (->
    if @onShow && !@get 'hidden'
      @onShow()
  ).observes('hidden')

  animate: ({$cssElement, properties, duration, easing, delay, callback}) ->
    $cssElement = $cssElement or @topLevelCssElement or @$()
    duration    = duration or @duration
    easing      = easing or @easing

    _animate = =>
      $cssElement.animate properties,
        duration: duration
        easing: easing
        complete: callback

    if delay? then setTimeout _animate, delay
    else _animate()

  animateSequence: ({$cssElement, sequence, repeat, delay, callback}) ->
    repeat ?= 1

    _animate = =>
      for i in [0...repeat] by 1
        for {properties, duration, easing}, j in sequence
          isLast = i is repeat - 1 and j is sequence.length - 1
          @animate({$cssElement, properties, duration, easing, callback: if isLast then callback else undefined})

    if delay? then setTimeout _animate, delay
    else _animate()

  ### Some view-specific animations below, to keep the view code cleaner

