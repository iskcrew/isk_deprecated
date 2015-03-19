@isk or= {}

shadername=
  fs: 'fragmentShader'
  vs: 'vertexShader'

effectname=
  c0: 'normal'
  c1: 'normal'
  c2: 'update'
  c3: 'alert'
  u0: 'update'
  u1: 'update'
  u2: 'update'
  u3: 'alert'

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
    geometry = new THREE.PlaneBufferGeometry( 192, 108,0,0 )
    @tex1=new THREE.Texture( $('#empty')[0] )
    @tex2=new THREE.Texture( $('#empty')[0] )
    @tex_empty=new THREE.Texture( $('#empty')[0] )
    @tex1.needsUpdate=true
    @tex2.needsUpdate=true
    @tex_empty.needsUpdate=true
    @cu=
         from: { type: "t", value: @tex1}
         to: { type: "t", value: @tex2}
         empty: { type: "t", value: @tex_empty}
         time: { type: "1f", value: 0.0 }
         transition_time: { type: "1f", value: 0.0 }
    @default_material=new THREE.MeshBasicMaterial(map: @tex2)
    
    @mesh = new THREE.Mesh( geometry, @default_material )
    @scene.add( @mesh )

    #@stats = new Stats()


  animate: (t) =>
    @stats?.begin()

    if not @start_t?
        @start_t = t
        @prev_t = 0
    [@prev_t, dt] = [t, t-@prev_t]

    @cu.time.value += 0.001 * dt
    if @transition_active()
      @transition_progress(dt)

    @renderer.render @scene, @camera

    @stats?.end()
    requestAnimationFrame @animate

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
    @cu.transition_time.value += 0.001 * dt
    if @cu.transition_time.value >= 1
      @change_slide_end()

  transition_active: ->
    @cu.transition_time.value != 0

  change_slide: (slide, update) ->
    d=$(slide).data()
    if @transition_active()
        @change_slide_end()
    @tex2.image = slide
    @tex2.needsUpdate = true

    if update
      @transition_start effectname['u'+d.slide.effect_id]
    else
      @transition_start effectname['c'+d.slide.effect_id]

  change_slide_end: ->
    @tex1.image = @tex2.image
    @tex1.needsUpdate = true
    @transition_stop()

renderer=new IskDisplayRenderer()

$ -> renderer.run()

#EXPORTS:
@isk.renderer = renderer

