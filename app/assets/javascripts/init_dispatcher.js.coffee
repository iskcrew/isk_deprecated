#
#  init_dispatcher.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-06.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

# Function for trying to reconnect 1 second after websocket connection is lost
# We need the delay as the connection will also be closed when the user goes to another page
# Without the delay the user would see the dialog box every time he clicks a link in isk.
popup_connection_lost = ->
	confirm_reconnect = ->
		if confirm("Websocket connection lost. Try to reconnect?") then window.dispatcher.reconnect()
	timer = setTimeout( confirm_reconnect, 5000 )

# Create one global WebSocketRails javascript client that we can use when needed.
# This avoids having multiple redundant connections open from different js-scripts.
window.dispatcher = new WebSocketRails(window.location.host + '/websocket')

# Register callbacks on the connection itself, currently they aren't 
# proganated to the main WebSocketRails class.
window.dispatcher._conn.on_close = popup_connection_lost
