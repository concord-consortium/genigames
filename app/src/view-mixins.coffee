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

  ###

GG.PointsToolTip = Ember.Mixin.create

  showToolTip: true
  toolTipText: null
  costPropertyName: null

  attributeBindings: ['tooltip']

  tooltip: (->
    if not @get 'showToolTip'
      return ""

    costPropertyName = @get 'costPropertyName'
    cost = GG.actionCostsController.getCost costPropertyName
    costStr = if cost then "<br/><br/>Cost: #{cost} rep points." else ""
    return @get('toolTipText') + costStr
  ).property('showToolTip', 'costPropertyName', 'toolTipText')

  toggleToolTip: (->
    if @get('showToolTip') and @get('tooltip')
      @$().qtip 'destroy' if @get 'qtip'

      params = GG.QTipDefaults
      params.content = @get 'tooltip'
      @set 'qtip', @$().qtip params
    else if @get 'qtip'
      @$().qtip 'destroy'
      @set 'qtip', null
  ).observes('showToolTip', 'tooltip')

  didInsertElement: ->
    @_super()
    @toggleToolTip()

GG.QTipDefaults =
  show: 'mouseover'
  hide: 'mouseout click'
  position:
    corner:
     target: 'bottomMiddle'
     tooltip: 'topLeft'
  style:
    border:
     width: 1
     radius: 8
    tip: 'topLeft'
    color: '#333'
    name: 'cream'
