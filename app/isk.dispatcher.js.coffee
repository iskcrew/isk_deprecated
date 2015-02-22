@isk or= {}

timer=undefined
connection_lost = (msg) ->
  console.log "Connection lost", msg?.type, msg
  $('#errors #connection').addClass('active')
  reconnect = ->
    console.log "Reconnection attempt"
    dispatcher.reconnect()
    timer = setTimeout( reconnect, 10000 )
  timer = setTimeout( reconnect, 1000 ) if not timer?

dispatcher = new WebSocketRails(window.location.host + '/websocket')

#dispatcher.bind 'connection_error', handler=connection_lost
dispatcher.bind 'connection_closed', handler=connection_lost

dispatcher.on_open = ->
  if not dispatcher?.connection_stale()
    $('#errors #connection').removeClass('active')
    clearTimeout(timer)
    timer=undefined

#EXPORTS:
@isk.dispatcher = dispatcher
