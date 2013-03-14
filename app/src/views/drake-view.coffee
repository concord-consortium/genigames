GG.DrakeView = Ember.View.extend
  templateName       : 'drake'
  classNames         : ['drake']
  classNameBindings  : ['selected','species']
  drakeImageName     : (->
    color = @get('org').getCharacteristic('color')
    color.charAt(0).toLowerCase() + color.slice(1) + ".png"
  ).property()
  drakeImage         : (->
    species = @get 'species'
    "../images/drakes/#{species}/" + @get 'drakeImageName'
  ).property('drakeImage')
  drakeIdleImage     : (->
    folder = @get 'currentAnimation.folder'
    species = @get 'species'
    "../images/drakes/#{species}/#{folder}/" + @get 'drakeImageName'
  ).property('drakeImage', 'currentAnimation')
  showAnimation      : false
  currentAnimation   : null
  width              : "200px"
  obstacleCourse       : false
  obstacleStateBinding : 'content.obstacleState'
  species: (->
    @get('content.species')
  ).property()
  org : (->
    @get('content.biologicaOrganism')
  ).property().cacheable()
  selected: (->
    content = @get 'content'
    content is GG.breedingController.get('mother') or
      content is GG.breedingController.get('father')
  ).property('GG.breedingController.mother', 'GG.breedingController.father')
  body : (->
    tail = @get('org').getCharacteristic "tail"
    if tail is "Long tail"
      'drake-body-long-tail'
    else if tail is "Kinked tail"
      'drake-body-kinked-tail'
    else if tail is "Fat tail"
      'drake-body-fat-tail'
    else 'drake-body-short-tail'
  ).property()
  shine : (->
    metallic = @get('org').getCharacteristic('metallic')
    metallic is "Metallic"
  ).property()
  armor : (->
    armor = @get('org').getCharacteristic "armor"
    armor is "Armor"
  ).property()
  wings : (->
    wings = @get('org').getCharacteristic "wings"
    wings is "Wings"
  ).property()
  spikes : (->
    spikes = @get('org').getCharacteristic "spikes"
    if spikes is "Wide spikes"
      'drake-wide-spikes'
    else if spikes is "Medium spikes"
      'drake-medium-spikes'
    else false
  ).property()
  head : (->
    sex = if @get('content.sex') is GG.FEMALE then "female" else "male"
    'drake-'+sex
  ).property()
  horns : (->
    horns = @get('org').getCharacteristic "horns"
    if horns is "Forward horns"
      'drake-forward-horns'
    else if horns is "Upward horns"
      'drake-upward-horns'
    else 'drake-reverse-horns'
  ).property()
  fire : (->
    fire = @get('org').getCharacteristic "fire breathing"
    fire is "Fire breathing"
  ).property()
  neckpattern: (->
    pattern = @get('org').getCharacteristic 'neckpattern'
    if pattern is "Striped neck"
      'drake-striped-neck'
    else if pattern is "Spotted neck"
      'drake-spotted-neck'
    else false
  ).property()
  fin: (->
    fin = @get('org').getCharacteristic 'fin'
    if fin is "Large fin"
      'drake-large-fin'
    else if fin is "Medium fin"
      'drake-medium-fin'
    # small fin is part of the body artwork
    else false
  ).property()
  didInsertElement: ->
    return if GG.baselineController.get('isBaseline') # no animations in baseline
    #return if @get 'obstacleCourse' # don't automatically start obstacle course animations

    # Wait for the animation images to load, then move it in place and start it up
    setupAnimation = =>
      GG.breedingController.removeObserver 'isShowingBreeder', setupAnimation
      @setNextIdleInterval()

    if GG.breedingController.get 'isShowingBreeder'
      setupAnimation()
    else
      GG.breedingController.addObserver 'isShowingBreeder', setupAnimation

  # Wait for the animation images to load, then move it in place and start it up
  swapImage: ->
    if @get('isDestroyed') then return

    onComplete = =>
      if @get('isDestroyed') then return
      Ember.run.next =>
        $(layer + ' .drake-idle-img').imagesLoaded =>
          time = if @get('obstacleState')? then 800 else 3000
          setTimeout =>
            # rescale animation image width before showing
            width = @get('currentAnimation.frames') * 100
            $(layer + ' .drake-idle-img').css "width", "#{width}%"
            $(layer + ' .idle').show()
            # rm static image
            requestAnimationFrame =>
              $(layer + ' .static').hide()
              @idleAnimation()
              @setNextIdleInterval()
          , time  # this timeout is a hack to remove the blink between showing the static and idle images on FF

    @set('showAnimation', true)

    # show static and hide animation while we wait for image to load
    layer = '#' + @get('elementId')
    $("#{layer} .static").show()
    $("#{layer} .idle").hide()

    $("#{layer} .idle").imagesLoaded onComplete

  shownTraitAnimations: {}
  hasShownObstacleAnimation: false

  _notShownTraitAnimation: (trait)->
    shown = @get 'shownTraitAnimations'
    !(shown[trait]? and shown[trait])

  _setShownTraitAnimation: (trait)->
    shown = @get 'shownTraitAnimations'
    shown[trait] = true
    @set 'shownTraitAnimations', shown

  animateObstacleResult: (->
    if @get('obstacleCourse') and @get('obstacleState')?
      @set 'hasShownObstacleAnimation', false
      @setNextIdleInterval()
  ).observes('obstacleState')

  setNextAnimation: ->
    if @get('isDestroyed') then return

    # if a drake has both fire and shine, then we want fire to show up 1/3 of the time,
    # and shine to show up 1/3 of the time (50% of the remaining 2/3). Otherwise, fire
    # should show up 1/2 of the time.
    fireOdds = if @get('shine') then 0.333 else 0.5

    if (@get('obstacleCourse') and @get('obstacleState')?)
      state = @get('obstacleState')
      @set 'currentAnimation', GG.drakeAnimations.obstacleAnimations[state]
      @set 'hasShownObstacleAnimation', true
    else if @get('fire') and (@_notShownTraitAnimation('fire') or Math.random() < fireOdds)
      @set 'currentAnimation', GG.drakeAnimations.traitAnimations.firebreath
      @_setShownTraitAnimation('fire')
    else if @get('shine') and (@_notShownTraitAnimation('shine') or Math.random() < 0.5)
      @set 'currentAnimation', GG.drakeAnimations.traitAnimations.metallic
      @_setShownTraitAnimation('shine')
    else
      @set 'currentAnimation', GG.drakeAnimations.idleAnimations.headTurn

  setNextIdleInterval: ->
    if (@get 'hasShownObstacleAnimation') then return

    if (@get('shine') and @_notShownTraitAnimation('shine')) or
        (@get('fire') and @_notShownTraitAnimation('fire')) or
        (@get('obstacleCourse') and @get('obstacleState')?)
      nextTime = 50
    else nextTime = Math.random() * 6000
    setTimeout =>
      @setNextAnimation()
      @swapImage()
    , nextTime
  idleAnimation: ->
    if !@$('img')
      return
    frames = @get 'currentAnimation.frames'
    force = @get('obstacleCourse')

    if force then callback = ->
      GG.animateDrake @$('.drake-idle-img'), frames, force

    GG.animateDrake @$('.drake-idle-img'), frames, force, callback

# Here we create one single animation timer, and add new images
# to an array so we can animate multiple drakes at once without
# creating a separate timer for each
GG.animateDrake = ($img, frames, force, callback) ->
  if GG.drakeAnimationList.length > 1 and !force
    return

  GG.drakeAnimationList.push $img
  GG.drakeAnimationPositions.push 0
  GG.drakeAnimationLengths.push frames
  GG.drakeAnimationCallbacks.push callback

  draw = ->
    setTimeout =>
      if GG.drakeAnimationList.length > 0
        # queue up the next frame
        requestAnimationFrame draw, $img
      else
        GG.drakeAnimationRunning = false

      i = GG.drakeAnimationList.length
      if i is 0
        clearInterval GG.drakeAnimationTimer
        GG.drakeAnimationTimer = null
        return
      while (i--)
        pos = GG.drakeAnimationPositions[i] = GG.drakeAnimationPositions[i] + 1
        if pos >= GG.drakeAnimationLengths[i]
          GG.drakeAnimationList[i].css({left:"0%"})
          GG.drakeAnimationList.splice(i, 1)
          GG.drakeAnimationPositions.splice(i, 1)
          GG.drakeAnimationLengths.splice(i, 1)
          callback = GG.drakeAnimationCallbacks.splice(i, 1)[0]
          if callback then callback()
        else
          GG.drakeAnimationList[i].css({left:"-"+(pos*100)+"%"})
    , 83  # ~ 12 fps

  if !GG.drakeAnimationRunning
    GG.drakeAnimationRunning = true
    requestAnimationFrame draw, $img

GG.drakeAnimationList      = []
GG.drakeAnimationPositions = []
GG.drakeAnimationLengths   = []
GG.drakeAnimationCallbacks = []

GG.drakeAnimationRunning = false


###
  Object for keeping information about individual drake animations.

  All idle animations can go under the "idleAnimations" property, so we can randomly select
  between them. We can follow the same pattern for other animations whenever we don't care
  which of a set we use.
###

GG.drakeAnimations =
  idleAnimations:
    headTurn:
      folder: 'headturn'
      frames: 15
  traitAnimations:
    firebreath:
      folder: 'firebreath'
      frames: 15
    metallic:
      folder: 'shine'
      frames: 7
  obstacleAnimations:
    successSmall:
      folder: 'successSmall'
      frames: 15
    successLarge:
      folder: 'successLarge'
      frames: 15
    fail:
      folder: 'fail'
      frames: 15