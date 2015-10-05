@isk or= {}

default_shader=
  fs: 'uniform sampler2D to; varying vec2 vUv; void main() {gl_FragColor = texture2D(to, vec2(vUv));}'
  vs: 'varying vec2 vUv; void main() {vUv=uv; gl_Position = vec4(position, 1.0);}'

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

my_get= (uri, cb) ->
  request = new XMLHttpRequest()
  request.open('GET', uri, true)

  request.onload = () ->
    if (this.status >= 200 && this.status < 400)
      cb this.response
    else
      cb null

  request.onerror = () ->
    cb null

  request.send()

my_getJSON= (uri, cb) ->
  my_get uri, (json) ->
    data = null
    data = JSON.parse(json) if json
    cb data

class QueuePool
  constructor: (@maxlen=5) ->
    @_order = []
    @_data = {}

  contains: (name) ->
    @_data[name]?

  full: () ->
    @_order.length >= @maxlen

  _push_name: (name) ->
    @_order.unshift(name)
    name

  _pop_name: (name) ->
    i = @_order.indexOf(name)
    if i >= 0
      @_order.splice(i, 1)
    else if @full()
      name=@_order.pop()
    else
      name=undefined
    name

  release: (name, item) ->
    @_push_name(name)
    @_data[name]=item
    console.debug "QueuePool: RELEASE", @_order, name, item
    item

  take: (name, no_delete=false) ->
    tempname=@_pop_name(name)
    item=@_data[tempname]
    delete @_data[tempname] if not no_delete or name != tempname
    item

  loan: (name) ->
    item=@take(name, true)
    console.debug "QueuePool: LOAN", @_order, name, item
    @release(name, item) if item?
    item


class IskDisplayRenderer
  init_shaders: (uri)->
    my_getJSON uri+'/index.json', (@shaders) =>
      for name, value of @shaders
        do (name, value) =>
          value.material = new THREE.ShaderMaterial(uniforms: @cu)
          for type in ['fs', 'vs']
            do (type) ->
              my_get uri + '/' + value.name + '.' + type, (code) ->
                value[type]=code
                value.material[shadername[type]]=code
                if value.fs? and value.vs?
                  value.material.needsUpdate=true

  init_local_control_handlers: ->
    isk?.local_broker?.register 'get shaders', @handle_get_shaders.bind(@)
    isk?.local_broker?.register 'set shaders', @handle_set_shaders.bind(@)

  handle_get_shaders: ->
    shadercodes={}
    for name, value of @shaders
      do (name, value) =>
        shadercodes[name]={}
        for type in ['fs', 'vs']
          shadercodes[name][type]=value[type]
    isk?.local_broker?.trigger 'return shaders', shadercodes

  handle_set_shaders: (shadercodes) ->
    console.log "handle_set_shaders: ", shadercodes
    for name, value of @shaders
      do (name, value) =>
        for type in ['fs', 'vs']
          value.material[shadername[type]] = value[type] = shadercodes[name][type]
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
    @renderer = new THREE.WebGLRenderer({antialias: false, precision: 'lowp'})
    @renderer.setSize(window.innerWidth, window.innerHeight)
    @renderer.autoClear = false

    @scene = new THREE.Scene()
    @camera = new THREE.PerspectiveCamera( 90.0, window.innerWidth/window.innerHeight, 1.0, 10000.0 )
    @camera.position.z = 108.0/2

    #geometry = new THREE.BoxGeometry( 20.0, 20.0, 20.0 )
    geometry = new THREE.PlaneBufferGeometry(2,2,0,0)
    #geometry = new THREE.PlaneGeometry( 192, 108,0,0 )
    @tex_empty=new THREE.Texture(document.getElementById('empty'))
    @tex_empty.minFilter=THREE.LinearFilter
    @tex_empty.needsUpdate=true
    @cu=
         from: { type: "t", value: @tex_empty}
         to: { type: "t", value: @tex_empty}
         empty: { type: "t", value: @tex_empty}
         time: { type: "1f", value: 0.0 }
         delta_time: { type: "1f", value: 0.0 }
         transition_time: { type: "1f", value: 0.0 }

    @default_material or= new THREE.ShaderMaterial(uniforms: @cu)
    for type, code of default_shader
      @default_material[shadername[type]]=code
    @default_material.needsUpdate=true
    
    @mesh = new THREE.Mesh( geometry, @default_material )
    @scene.add( @mesh )

    @stats = new Stats?()


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
    @observer = new MutationObserver (mutations) ->
      mutations.forEach (mutation) ->
        if mutation?.attributeName =='class'
          if mutation.target.classList.contains('updated')
            console.debug "Mutation observer: updated", mutation.target.classList, mutation
            isk.renderer.change_slide mutation.target, true
          else if mutation.target.classList.contains('current')
            console.debug "Mutation observer: current", mutation.target.classList, mutation
            isk.renderer.change_slide mutation.target
        return null
      return null
 
    config = {subtree: true, attributes: true}
    @observer.observe(target, config)

  run: (stats=true) ->
    @init_local_control_handlers()
    @init_renderer()
    @init_shaders 'effects'
    @init_observer document.querySelector('#pres')
    requestAnimationFrame @animate

    if stats and @stats?
      document.getElementById('stats').appendChild(@stats?.domElement)

    document.getElementById('canvas').appendChild(@renderer?.domElement)

    # Add window size event and run it once (to set initial values)
    window.addEventListener('resize', @handle_window_size, false)
    @handle_window_size()

    THREEx?.FullScreen?.request()

  transition_start: (type) ->
    @mesh.material = @shaders?[type]?['material'] or @default_material
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
    @texpool or= new QueuePool(25)

    console.debug 'renderer: change_slide', slide, update
    d=slide?.iskSlide
    tex=@texpool.loan(d.uid)
    if not tex
      console.debug "Creating new texture"
      tex = new THREE.Texture()
      @texpool.release(d.uid, tex)
    if tex?.image?.iskSlide?.uid != d.uid
      tex.image=slide
      tex.minFilter=THREE.LinearFilter
      tex.needsUpdate = true

      t=performance.now()
      @renderer.uploadTexture tex
      t-=performance.now()
      console.debug "Loaded texture in ", (-t).toFixed(2), Date()

    if @transition_active()
      @change_slide_end()

    effect_id=d?.effect_id or ""
    effect_name=undefined
    if update
      effect_name = effectname['u'+effect_id]
    else
      effect_name = effectname['c'+effect_id]

    @transition_start effect_name
    @cu.to.value=tex

  change_slide_end: ->
    @cu.from.value = @cu.to.value
    @transition_stop()

renderer=new IskDisplayRenderer()

# TODO better alternative for $ -> renderer.run()
renderer.run()

#EXPORTS:
@isk.renderer = renderer

