# 
#  websocket_connection.js.coffee
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-16.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 
# Initialize one ws connection for use on all our scripts

window.dispatcher = new WebSocketRails(window.location.host + '/websocket')