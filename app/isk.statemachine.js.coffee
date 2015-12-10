@isk or= {}

connection = StateMachine.create
  initial: 'INIT'
  error: (msg...) ->
    console.log 'CONNECTION fsm-error ', msg
  events: [
    { name: 'websocket_error', from: 'INIT',  to: 'OUT' }
    { name: 'websocket_connected', from: 'INIT',  to: 'READY' }

    { name: 'close', from: ['READY', 'RECON', 'ERR'],  to: 'CLOSING' }
    { name: 'websocket_closed', from: ['READY', 'CLOSING'],  to: 'CLOSED' }
    { name: 'open', from: 'CLOSED',  to: 'RECON' }

    { name: 'websocket_error',  from: ['READY', 'RECON'], to: 'ERR' }
    { name: 'websocket_closed',  from: 'ERR', to: 'RECON' }

    { name: 'websocket_connected',  from: 'RECON', to: 'READY' }
   
  ]
  callbacks:
    onenterstate: (msg...) -> console.log "CONNECTION: State: ", msg
    
    onINIT: ->
      isk.remote.connect
        onopen:  @websocket_connected.bind @
        onclose: @websocket_closed.bind @
        onerror: @websocket_error.bind @

    onRECON: ->
      isk.remote.connect
        onopen:  @websocket_connected.bind @
        onclose: @websocket_closed.bind @
        onerror: @websocket_error.bind @

    onOUT: ->
      # TODO: BIG ERROR
      isk.remote.disconnect()
      app.exit() if app.can('exit')

    onREADY: ->
      app.connection_ready() if app.can('connection_ready')
      isk.errors.connection(false)

    onleaveREADY: ->
      isk.errors.connection(true)

    onCLOSING: ->
      isk.remote.disconnect()
    onERR: ->
      isk.remote.disconnect()

app = StateMachine.create
  initial: 'STOPPED'
  error: (msg...) ->
    console.log 'APP fsm-error ', msg
  events: [
    { name: 'exit', from: 'RUNNING', to: 'STOPPED'  }
    { name: 'run',  from: 'STOPPED',    to: 'STOPPED' }
    { name: 'connection_ready',  from: 'STOPPED',    to: 'RUNNING' }
  ]
  callbacks:
    onenterstate: (msg...) -> console.log "APP: State: ", msg
    onenterRUNNING: ->
      isk.client.start()
      isk.errors.stopped(false)
      isk.renderer.run()
    onleaveRUNNING: ->
      isk.client.stop()
      isk.errors.stopped(true)
      connection.close()
      isk.renderer.pause()
      
    onrun: -> connection.open() if connection.can('open')


#EXPORTS:
@isk.fsm=
  connection: connection
  app: app
  run: -> app.run()
  exit: -> app.exit()

