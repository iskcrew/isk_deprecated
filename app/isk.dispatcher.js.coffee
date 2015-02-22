@isk or= {}

dispatcher = new WebSocketRails(window.location.host + '/websocket')

#dispatcher.disconnect()

#dispatcher.bind 'connection_error', handler=connection_lost
dispatcher.bind 'connection_closed', handler = (msg) ->
  console.log "Connection lost", msg?.type, msg
  isk.fsm.websocket_error()

dispatcher.on_open = (msg) ->
  console.log "Connection established", msg?.type, msg
  isk.fsm.websocket_connected()

#EXPORTS:
@isk.dispatcher = dispatcher
