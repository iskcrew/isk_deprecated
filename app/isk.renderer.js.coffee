@isk or= {}

shadername=
  fs: 'fragmentShader'
  vs: 'vertexShader'

effectname=
  c: 'benchmark'
  u: 'benchmark'
  c0: 'normal'
  c1: 'normal'
  c2: 'update'
  c3: 'alert'
  u0: 'update'
  u1: 'update'
  u2: 'update'
  u3: 'alert'
  c4: 'benchmark'
  u4: 'benchmark'

class IskDisplayRenderer
  init_shaders: (uri)->
    $.getJSON uri+'/index.json', (@shaders) =>
      for name, value of @shaders
        do (name, value) =>
          value.material = new THREE.ShaderMaterial(uniforms: @cu)
          for type in ['fs', 'vs']
            do (type) ->
              $.get uri + '/' + value.name + '.' + type, (code) ->
                value[type]=code
                value.material[shadername[type]]=code
                if value.fs? and value.vs?
                  value.material.needsUpdate=true

  handle_window_size: =>
    elem=@renderer.domElement?.parentNode?.parentNode?.firstElementChild?.firstElementChild
    [w,h]=[elem?.clientWidth,elem?.clientHeight]
    if not w? and h?
      [w,h]=[window?.innerWidth,window?.innerHeight]
    @renderer.setSize( w,h )
    @camera.aspect = w/h
    @camera.updateProjectionMatrix()

  init_renderer: ->
    @renderer = new THREE.WebGLRenderer({antialias: true})
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.autoClear = false

    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera( 90.0, window.innerWidth/window.innerHeight, 1.0, 10000.0 )
    @camera.position.z = 108.0/2

    #geometry = new THREE.BoxGeometry( 20.0, 20.0, 20.0 )
    geometry = new THREE.PlaneBufferGeometry(2,2,0,0)
    #geometry = new THREE.PlaneGeometry( 192, 108,0,0 )
    @tex_empty=new THREE.Texture( $('#empty')[0] )
    @tex_empty.minFilter=THREE.LinearFilter
    @tex_empty.needsUpdate=true
    @cu=
         from: { type: "t", value: @tex_empty}
         to: { type: "t", value: @tex_empty}
         empty: { type: "t", value: @tex_empty}
         time: { type: "1f", value: 0.0 }
         delta_time: { type: "1f", value: 0.0 }
         transition_time: { type: "1f", value: 0.0 }
    @default_material or= new THREE.MeshBasicMaterial(map: @tex_empty)
    
    @mesh = new THREE.Mesh( geometry, @default_material )
    @scene.add( @mesh )

    #@stats = new Stats()


  animate: (t) =>
    requestAnimationFrame @animate
    @stats?.begin()

    if not @start_t?
        @start_t = t
        @prev_t = 0
    [@prev_t, dt] = [t, t-@prev_t]

    @cu.time.value += 0.001 * dt
    #@cu.delta_time.value = 0.001 * dt
    @cu.delta_time.value = (0.00001 * dt + @cu.delta_time.value * 0.99)
    if @transition_active()
      @transition_progress(dt)

    @renderer.render @scene, @camera

    @stats?.end()

  init_observer: (target) ->
    @observer = new MutationObserver (mutations) =>
      mutations.forEach (mutation) =>
        if mutation?.attributeName =='class'
          if mutation.target.classList.contains('updated')
            mutation.target.classList.remove('updated')
            @change_slide mutation.target, true
          else if mutation.target.classList.contains('current')
            @change_slide mutation.target
 
    config = {subtree: true, attributes: true}
    @observer.observe(target, config)

  run: (stats=true) ->
    @init_renderer()
    @init_shaders 'effects'
    @init_observer document.querySelector('#pres')
    requestAnimationFrame @animate

    $('#stats').append(@stats?.domElement) if stats and @stats?

    $(@renderer.domElement).hide().fadeIn(2000)
    $('#canvas').append(@renderer?.domElement)

    # Add window size event and run it once (to set initial values)
    window.addEventListener('resize', @handle_window_size, false)
    @handle_window_size()

    THREEx?.FullScreen?.request()

  transition_start: (type) ->
    @mesh.material=m if m=@shaders?[type]?['material']
    @cu.transition_time.value = 0.00000001
    @cu.time.value = 0

  transition_stop: ->
    @cu.transition_time.value = 0

  transition_progress: (dt) ->
    delta=Math.min(dt, 50)
    @cu.transition_time.value += 0.001 * delta
    if @cu.transition_time.value >= 1
      @change_slide_end()

  transition_active: ->
    @cu.transition_time.value > 0

  change_slide: (slide, update) ->
    @texstore or= {}
    console.debug 'renderer: change_slide', slide, update
    d=slide?.iskSlide
    @texstore[d?.id] or= new THREE.Texture(slide)
    if not d?.uptodate
      d.uptodate = true
      @texstore[d?.id].minFilter=THREE.LinearFilter
      @texstore[d?.id].needsUpdate = true
      t=performance.now()
      @renderer.uploadTexture @texstore[d?.id]
      t-=performance.now()
      console.log "Loaded texture in ", (-t).toFixed(2), Date()

    if @transition_active()
      @change_slide_end()

    effect_id=d?.effect_id or ""
    effect_name=undefined
    if update
      effect_name = effectname['u'+effect_id]
    else
      effect_name = effectname['c'+effect_id]

    @transition_start effect_name
    @cu.to.value=@texstore[d?.id]

  change_slide_end: ->
    @cu.from.value = @cu.to.value
    @transition_stop()

renderer=new IskDisplayRenderer()

$ -> renderer.run()

#EXPORTS:
@isk.renderer = renderer

