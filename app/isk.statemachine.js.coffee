@isk or= {}

connection = StateMachine.create
  initial: 'CONN'
  error: (msg...) ->
    console.log 'CONNECTION fsm-error ', msg
  events: [
    { name: 'conn_failed', from: 'CONN',  to: 'OUT' }
    { name: 'conn_success', from: 'CONN',  to: 'IN' }
    
    { name: 'login', from: 'OUT',  to: 'CONN' }
    { name: 'logout', from: '*',  to: 'OUT' }
    
    { name: 'websocket_error',  from: 'READY', to: 'IN' }
    { name: 'websocket_connected',  from: 'IN', to: 'READY' }
    { name: 'reconnect',  from: 'IN', to: 'IN' }
   
  ]
  callbacks:
    onenterstate: (msg...) -> console.log "CONNECTION: State: ", msg
    
    onCONN: -> isk.menu.displays.show()
    
    onOUT: ->
      isk.show_login()
      isk.remote.disconnect()
      isk.menu.displays.hide()
      app.normal() if app.can('normal')

    onleaveCONN: -> isk.show_logout()

    onREADY: ->
      app.autostart() if app.can('autostart')
      isk.errors.connection(false)

    onleaveREADY: ->
      isk.errors.connection(true)

    onIN: ->
      job = =>
        if @can 'reconnect'
          @reconnect()
          setTimeout(job, 5000)
      setTimeout(job, 1000)

    onreconnect: -> isk.remote.reconnect()

app = StateMachine.create
  initial: 'INIT'
  error: (msg...) ->
    console.log 'APP fsm-error ', msg
  events: [
    { name: 'autostart', from: 'INIT', to: 'RUNNING' }
    { name: 'normal', from: 'INIT', to: 'MENU' }

    { name: 'exit', from: 'RUNNING', to: 'MENU'  }
    { name: 'run',  from: 'MENU',    to: 'RUNNING' }
  ]
  callbacks:
    onenterstate: (msg...) -> console.log "APP: State: ", msg
    onINIT: ->
      if not isk.display_name.get()?
        isk.client.stop()
        @normal()


    onenterMENU: -> isk.menu.show()
    onleaveMENU: -> isk.menu.hide()

    onenterRUNNING: ->
      isk.client.start(isk.display_name.get())
      isk.errors.stopped(false)
    onleaveRUNNING: ->
      isk.client.stop()
      isk.errors.stopped(true)
      
    onbeforeexit: -> isk.display_name.clear()
    
    onbeforeautostart: -> return false if not isk.display_name.get()
    onbeforerun: -> return false if not isk.display_name.get()


#EXPORTS:
@isk.fsm=
  connection: connection
  app: app
  run: -> app.run()
  exit: -> app.exit()
  login: -> connection.login()
  logout: -> connection.logout()
  conn_failed: -> connection.conn_failed() #if connection.can('conn_failed')
  conn_success: -> connection.conn_success() #if connection.can('conn_success')
  websocket_error: -> connection.websocket_error() #if connection.can('websocket_error')
  websocket_connected: -> connection.websocket_connected() #if connection.can('websocket_connected')

