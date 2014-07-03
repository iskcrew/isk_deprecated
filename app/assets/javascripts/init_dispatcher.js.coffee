popup_connection_lost = ->
	alert_connection_lost = ->
		alert 'Websocket connection lost, reload page to reconnect'
	timer = setTimeout( alert_connection_lost, 1000 )
	
window.dispatcher = new WebSocketRails(window.location.host + '/websocket')
window.dispatcher._conn._conn.onclose = popup_connection_lost
window.dispatcher._conn._conn.onerror = popup_connection_lost
