GG.DrakeView = Ember.View.extend
  templateName       : 'drake'
  classNames         : ['drake']
  classNameBindings  : ['selected']
  drakeImageName     : (->
    color = @get('org').getCharacteristic('color')
    color.charAt(0).toLowerCase() + color.slice(1) + ".png"
  ).property()
  drakeImage         : (->
    '../images/drakes/' + @get 'drakeImageName'
  ).property('drakeImage')
  drakeIdleImage     : (->
    folder = @get 'currentAnimation.folder'
    "../images/drakes/#{folder}/" + @get 'drakeImageName'
  ).property('drakeImage', 'currentAnimation')
  showAnimation      : false
  currentAnimation   : null
  width              : "200px"
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
    else 'drake-reverse-horns'
  ).property()
  fire : (->
    fire = @get('org').getCharacteristic "fire breathing"
    fire is "Fire breathing"
  ).property()
  didInsertElement: ->
    return if GG.baselineController.get('isBaseline') # no animations in baseline

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

    onComplete = =>
      if @get('isDestroyed') then return
      Ember.run.next =>
        $(layer + ' .drake-idle-img').imagesLoaded =>
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
          , 4000  # this timeout is a hack to remove the blink between showing the static and idle images on FF

    @set('showAnimation', true)

    # show static and hide animation while we wait for image to load
    layer = '#' + @get('elementId')
    $("#{layer} .static").show()
    $("#{layer} .idle").hide()

    $("#{layer} .idle").imagesLoaded onComplete

  hasShownTraitAnimation: false

  setNextAnimation: ->
    # hard-coded animation selection, knowing that we just have headturn and metallic.
    # next we will want more interesting automatic selection based on the presense
    # of arbitrary traits
    if @get('shine') and (!@get('hasShownTraitAnimation') or Math.random() < 0.5)
      @set 'currentAnimation', GG.drakeAnimations.traitAnimations.metallic
      @set 'hasShownTraitAnimation', true
    else
      @set 'currentAnimation', GG.drakeAnimations.idleAnimations.headTurn

  setNextIdleInterval: ->
    if @get('shine') and !@get 'hasShownTraitAnimation'
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
    GG.animateDrake @$('.drake-idle-img'), frames

# Here we create one single animation timer, and add new images
# to an array so we can animate multiple drakes at once without
# creating a separate timer for each
GG.animateDrake = ($img, frames) ->
  if GG.drakeAnimationList.length > 1 then return

  GG.drakeAnimationList.push $img
  GG.drakeAnimationPositions.push 0
  GG.drakeAnimationLengths.push frames

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
        else
          GG.drakeAnimationList[i].css({left:"-"+(pos*100)+"%"})
    , 83  # ~ 12 fps

  if !GG.drakeAnimationRunning
    GG.drakeAnimationRunning = true
    requestAnimationFrame draw, $img

GG.drakeAnimationList = []
GG.drakeAnimationPositions = []
GG.drakeAnimationLengths = []

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
    metallic:
      folder: 'shine'
      frames: 7