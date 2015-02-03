#
#  init_dispatcher.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-06.
#  Modified by Niko Vähäsarja on 2014-12-16.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

# Function for trying to reconnect 1 second after websocket connection is lost
# and once every 10 seconds after that.
# Indication of lost connection is subtly shown while connection is down
timer=undefined
connection_lost = (msg) ->
	console.log "Connection lost", msg?.type, msg
	$('#errors #connection').addClass('active')
	reconnect = ->
		console.log "Reconnection attempt"
		window.dispatcher.reconnect()
		timer = setTimeout( reconnect, 10000 )
	timer = setTimeout( reconnect, 1000 ) if not timer?

# Create one global WebSocketRails javascript client that we can use when needed.
# This avoids having multiple redundant connections open from different js-scripts.
window.dispatcher = new WebSocketRails(window.location.host + '/websocket')

# Register callbacks on the connection itself, currently they aren't 
# proganated to the main WebSocketRails class.
#window.dispatcher._conn.on_error = connection_lost
#window.dispatcher._conn.on_error = connection_lost
#window.dispatcher.bind 'connection_error', handler=connection_lost
window.dispatcher.bind 'connection_closed', handler=connection_lost

window.dispatcher.on_open = ->
	if not window.dispatcher?.connection_stale()
		$('#errors #connection').removeClass('active')
		clearTimeout(timer)
		timer=undefined
