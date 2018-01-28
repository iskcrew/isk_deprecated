@isk or= {}

connection = StateMachine.create
  initial: 'INIT'
  error: (msg...) ->
    console.log 'CONNECTION fsm-error ', msg
  events: [
    { name: 'retry',  from: 'ERR', to: 'INIT' }
    { name: 'open',  from: 'CLOSED', to: 'INIT' }
    { name: 'websocket_closed',  from: 'READY', to: 'INIT' }

    { name: 'websocket_connected', from: 'INIT',  to: 'READY' }

    { name: 'websocket_closed',  from: ['INIT', 'ERR'], to: 'ERR' }
    { name: 'websocket_error',  from: ['INIT', 'READY', 'ERR'], to: 'ERR' }
    { name: 'ping_timeout',  from: 'READY', to: 'ERR' }

    { name: 'websocket_closed',  from: 'CLOSED', to: 'CLOSED' }
    { name: 'close',  from: '*', to: 'CLOSED' }

  ]
  callbacks:
    onenterstate: (msg...) -> console.log "CONNECTION: State: ", msg
    
    onINIT: ->
      isk.errors.connection(true)
      isk.remote.connect
        onopen:  @websocket_connected.bind @
        onclose: @websocket_closed.bind @
        onerror: @websocket_error.bind @

    onREADY: ->
      app.connection_ready() if app.can('connection_ready')
      isk.errors.connection(false)
      isk.pingpong.start()

    onleaveREADY: ->
      isk.remote.disconnect()
      isk.errors.connection(true)
      isk.pingpong.stop()

    onERR: ->
      setTimeout ->
        connection.retry() if connection.can('retry')
      , 1000

    onCLOSED: ->
      isk.errors.loggedout(true)

    onleaveCLOSED: ->
      isk.errors.loggedout(false)

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
  run: -> app.run() if app.can('run')
  exit: -> app.exit() if app.can('exit')
  ping_timeout: -> connection.ping_timeout() if connection.can('ping_timeout')

