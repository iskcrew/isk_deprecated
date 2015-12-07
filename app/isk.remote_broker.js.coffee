@isk or= {}

cbs =
  _name: (object='*', method='*') ->
    "#{object}::#{method}"

  _exec: (object, method, data) ->
    @?[@_name(object, method)]?(data, {object, method})
    @?[@_name(undefined, method)]?(data, {object, method})
    @?[@_name(object, undefined)]?(data, {object, method})
    @?[@_name(undefined, undefined)]?(data, {object, method})

  _set: (object, method, cb) ->
    @[@_name(object, method)]=cb

  _del: (object, method, cb) ->
    name = @_name(object, method)
    delete @[name] if cb==undefined or @[name]==cb

tubesock_remote =
  connect: (@id) ->
    url = "#{window.location.protocol.replace('http', 'ws')}//#{window.location.host}#{window.location.pathname.replace('/dpy', '/websocket')}"
    @socket = new WebSocket url

    @socket.onerror = ->
      console.log "websocket error"
      isk.fsm.websocket_error()

    @socket.onopen = ->
      console.log "websocket opened"
      isk.fsm.websocket_connected()

    @socket.onmessage = (event) ->
      if event.data.length
        m = JSON.parse(event.data)
        console.debug "websocket message: ", m
        cbs._exec m[0], m[1], m[2]

  disconnect: ->
    @socket?.close()

  reconnect: (id) ->
    @id=id if id
    @disconnect()
    @connect(@id)

  unregister: ({object, method}, cb) ->
    cbs._del(object, method, cb)

  register: ({object, method}, cb) ->
    cbs._set(object, method, cb)

  trigger: (command, data) ->
    @socket.send(JSON.stringify([command, 'reserved', data or {} ]))

#EXPORTS:
@isk.remote = tubesock_remote
