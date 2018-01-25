@isk or= {}

default_shader=
  vs: 'attribute vec3 a_pos; attribute vec2 a_tex_uv; varying vec2 v_uv; void main() {v_uv=a_tex_uv.xy; gl_Position = vec4(a_pos, 1.0);}'
  fs: 'uniform sampler2D u_empty; varying vec2 v_uv; void main() {gl_FragColor = texture2D(u_empty, v_uv); \n}'

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

  insert: (name, item) ->
    @release(name, item)

class WebGLRenderer
  constructor: ->
    @domElement = document.createElement('canvas')
    @gl_context = @domElement.getContext('webgl')
    gl=@gl_context

    @TEX_UNIT = [gl.TEXTURE0, gl.TEXTURE1, gl.TEXTURE2, gl.TEXTURE3, gl.TEXTURE4, gl.TEXTURE5, gl.TEXTURE6, gl.TEXTURE7]

    @buffers =
      pos:
        buf: gl.createBuffer()
        array: [
          -1.0, -1.0, 1.0,
           1.0, -1.0, 1.0,
           1.0,  1.0, 1.0,
          -1.0,  1.0, 1.0 ]
      tex_uv:
        buf: gl.createBuffer()
        array: [
           0.0, 0.0,
           1.0, 0.0,
           1.0, 1.0,
           0.0, 1.0 ]
      index:
        buf: gl.createBuffer()
        array: [
          0, 1, 2,
          0, 2, 3 ]

    gl.bindBuffer( gl.ARRAY_BUFFER, @buffers.pos.buf )
    gl.bufferData( gl.ARRAY_BUFFER, new Float32Array( @buffers.pos.array ), gl.STATIC_DRAW )

    gl.bindBuffer( gl.ARRAY_BUFFER, @buffers.tex_uv.buf )
    gl.bufferData( gl.ARRAY_BUFFER, new Float32Array( @buffers.tex_uv.array ), gl.STATIC_DRAW )

    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, @buffers.index.buf)
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array( @buffers.index.array ), gl.STATIC_DRAW)

    @default_program or= @create_shader_program(default_shader)
    @current_program or= @default_program

  _create_shader: (  source, type ) ->
    gl = @gl_context

    shader = gl.createShader( type )
    gl.shaderSource( shader, source )
    gl.compileShader( shader )
    if ( !gl.getShaderParameter( shader, gl.COMPILE_STATUS ) )
      console.error( ( (type == gl.VERTEX_SHADER) ? "VERTEX" : "FRAGMENT" ) + " SHADER:\n" +
                       gl.getShaderInfoLog( shader ))
      return null
    return shader

  create_shader_program: (shader) ->
    gl = @gl_context

    vs = @_create_shader( "precision lowp float; \n" + shader.vs, gl.VERTEX_SHADER )
    fs = @_create_shader( "precision lowp float; \n" + shader.fs, gl.FRAGMENT_SHADER )

    if (vs? and fs?)
      program = gl.createProgram()
      gl.attachShader( program, vs )
      gl.attachShader( program, fs )
      gl.linkProgram( program )

    if (vs?)
      gl.deleteShader(vs)
    if (fs?)
      gl.deleteShader(fs)

    if ( !gl.getProgramParameter( program, gl.LINK_STATUS ))
      console.error( "VALIDATE_STATUS: " + gl.getProgramParameter( program, gl.VALIDATE_STATUS ) + "\n" +
                                        "ERROR: " + gl.getError() + "\n\n" +
                                        "- Vertex Shader -\n" + shader.vs + "\n\n" +
                                        "- Fragment Shader -\n" + shader.fs )
      return null

    return program

  render: (uniforms) ->
    gl = @gl_context

    gl.clear( gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT )
    gl.useProgram( @current_program )
    for name, item of uniforms
      if item?.location?
        if item.type == "1f"
          gl.uniform1f( item.location, item.value )
        else if item.type == "t"
          gl.uniform1i( item.location, item.texture_unit)
          gl.activeTexture(@TEX_UNIT[item.texture_unit])
          gl.bindTexture(gl.TEXTURE_2D, item.value.texture)

    gl.bindBuffer( gl.ARRAY_BUFFER, @buffers.pos.buf )
    gl.vertexAttribPointer( @buffers.pos.location, 3, gl.FLOAT, false, 0, 0 )
    gl.enableVertexAttribArray( @buffers.pos.location )

    gl.bindBuffer( gl.ARRAY_BUFFER, @buffers.tex_uv.buf )
    gl.vertexAttribPointer( @buffers.tex_uv.location, 2, gl.FLOAT, false, 0, 0 )
    gl.enableVertexAttribArray( @buffers.tex_uv.location )

    gl.bindBuffer( gl.ELEMENT_ARRAY_BUFFER, @buffers.index.buf )
    gl.drawElements( gl.TRIANGLES, 6, gl.UNSIGNED_SHORT, 0 )

    gl.disableVertexAttribArray( @buffers.pos.location )
    gl.disableVertexAttribArray( @buffers.tex_uv.location )

  create_texture: (slide) ->
    gl = @gl_context

    texture = gl.createTexture()
    gl.bindTexture(gl.TEXTURE_2D, texture)
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
    tex= { texture: texture, image: slide }
    @update_texture(tex)
    return tex

  update_texture: (tex) ->
    gl = @gl_context

    gl.bindTexture(gl.TEXTURE_2D, tex.texture)
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, tex.image)

  set_size: (w, h) ->
    gl = @gl_context
    gl.viewport(0, 0, w, h)
    @domElement.width=w
    @domElement.height=h

  set_program: (program, cu) ->
    @current_program = program or @default_program

  set_uniform_locations: (uniforms) ->
    gl = @gl_context
    for name, value of uniforms
      value.location = gl.getUniformLocation(@current_program, "u_"+name)
    @set_attribute_locations()

  set_attribute_locations: ->
    gl = @gl_context
    for name, value of @buffers
      value.location = gl.getAttribLocation(@current_program, "a_"+name)
      console.debug( "Attribute location -1", name, value ) if value.location == -1


class IskDisplayRenderer
  init_shaders: (uri)->
    my_getJSON uri+'/index.json', (@shaders) =>
      for name, value of @shaders
        do (name, value) ->
          value.shader or= {}
          for type in ['fs', 'vs']
            do (type) ->
              my_get uri + '/' + value.name + '.' + type, (code) ->
                value.shader[type]=code
                if value.shader?.fs? and value.shader?.vs?
                  value.program = isk.renderer.webgl.create_shader_program(value.shader)

  init_local_control_handlers: ->
    isk.local_broker?.register 'get shaders', @handle_get_shaders.bind(@)
    isk.local_broker?.register 'set shaders', @handle_set_shaders.bind(@)

  handle_get_shaders: ->
    shadercodes={}
    for name, value of @shaders
      do (name, value) ->
        shadercodes[name]={}
        for type in ['fs', 'vs']
          shadercodes[name][type]=value[type]
    isk.local_broker?.trigger 'return shaders', shadercodes

  handle_set_shaders: (shadercodes) ->
    console.log "handle_set_shaders: ", shadercodes
    for name, value of @shaders
      do (name, value) ->
        for type in ['fs', 'vs']
          value.material[shadername[type]] = value[type] = shadercodes[name][type]
        value.material.needsUpdate=true

  handle_window_size: =>
    w = window.innerWidth
    h = w * 9 / 16
    if h > window.innerHeight
      h = window.innerHeight
      w = h * 16 / 9
    @webgl.set_size(w, h)

  init_renderer: ->
    @tex_empty=@webgl.create_texture(document.getElementById('empty'))
    @cu=
         from: { type: "t", value: @tex_empty, texture_unit: 0}
         to: { type: "t", value: @tex_empty, texture_unit: 1}
         empty: { type: "t", value: @tex_empty, texture_unit: 2}
         time: { type: "1f", value: 0.0 }
         delta_time: { type: "1f", value: 0.0 }
         transition_time: { type: "1f", value: 0.0 }

    @webgl.set_uniform_locations(@cu)


  animate: (t) =>
    @_animation = requestAnimationFrame @animate

    if not @start_t?
      @start_t = t
      @prev_t = 0
    [@prev_t, dt] = [t, t-@prev_t]

    @cu.time.value += 0.001 * dt
    #@cu.delta_time.value = 0.001 * dt
    @cu.delta_time.value = (0.00001 * dt + @cu.delta_time.value * 0.99)
    if @transition_active()
      @transition_progress(dt)

    @webgl.render(@cu)

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

  constructor: ->
    @webgl=new WebGLRenderer()

    @init_local_control_handlers()
    @init_renderer()
    @init_shaders '/effects'
    @init_observer document.querySelector('#pres')

    document.getElementById('canvas').appendChild(@webgl.domElement)

    # Add window size event and run it once (to set initial values)
    window.addEventListener('resize', @handle_window_size, false)
    @handle_window_size()

  pause: ->
    cancelAnimationFrame @_animation
    @_animation = undefined

  run: ->
    if not @_animation?
      @_animation = requestAnimationFrame @animate

  transition_start: (type) ->
    console.debug('transition_start: ' +type)
    @webgl.set_program(@shaders?[type]?.program)
    @webgl.set_uniform_locations(@cu)
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
      tex = @webgl.create_texture(slide)
      @texpool.insert(d.uid, tex)
    else if tex?.image?.iskSlide?.uid != d.uid
      tex.image=slide
      @webgl.update_texture(tex)

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

#EXPORTS:
@isk.renderer = renderer
