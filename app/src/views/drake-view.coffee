GG.DrakeView = Ember.View.extend
  templateName       : 'drake'
  classNames         : ['drake']
  classNameBindings  : ['selected']
  drakeImageName     : (->
    color = @get('org').getCharacteristic('color').replace("Metallic ","")
    color.charAt(0).toLowerCase() + color.slice(1) + ".png"
  ).property()
  drakeImage         : (->
    '../images/drakes/' + @get 'drakeImageName'
  ).property('drakeImage')
  drakeIdleImage     : (->
    '../images/drakes/headturn/' + @get 'drakeImageName'
  ).property('drakeImage')
  showIdle           : false
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
    color = @get('org').getCharacteristic('color')
    ~color.indexOf "Metallic"
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
    swapImage = =>
      GG.breedingController.removeObserver 'isShowingBreeder', swapImage
      idleImg = new Image()
      idleImg.src = @get('drakeIdleImage')

      onComplete = =>
        setTimeout =>
          unless @get('isDestroyed')
            layer = '#' + @get('elementId')
            @set('showIdle', true)
            Ember.run.next =>
              $(layer + ' .drake-idle-img').imagesLoaded =>
                setTimeout =>
                  requestAnimationFrame =>
                    $(layer + ' .static').remove()
                    @setNextIdleInterval()
                , 2000  # this timeout is a hack to remove the blink between showing the static and idle images on FF
        , 2000

      if !idleImg.complete
        $(idleImg).bind('error load onreadystatechange', onComplete)
      else
        onComplete()

    if GG.breedingController.get 'isShowingBreeder'
      swapImage()
    else
      GG.breedingController.addObserver 'isShowingBreeder', swapImage

  setNextIdleInterval: ->
    nextTime = 3000 + Math.random() * 15000
    setTimeout =>
      @idleAnimation()
      @setNextIdleInterval()
    , nextTime
  idleAnimation: ->
    if !@$('img')
      return
    GG.animateDrake @$('.drake-idle-img')

# Here we create one single animation timer, and add new images
# to an array so we can animate multiple drakes at once without
# creating a separate timer for each
GG.animateDrake = ($img) ->
  if GG.drakeAnimationList.length > 1 then return

  GG.drakeAnimationList.push $img
  GG.drakeAnimationPositions.push 0
  GG.drakeAnimationLengths.push 15  # for the moment we assume animations are 15 frames

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
