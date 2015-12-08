#
# simple_editor.js.coffee
#  
# Update the html views via websocket messages
#
# Created by Vesa-Pekka Palmu on 2014-07-06.
# Copyright 2015 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	timer = 0
	request_svg = ->
		console.log "Requesting updated svg"
		data = {
			heading: $("#simple_head").val(),
			text: $("#simple_text").val(),
			text_size: $("#simple_text_size").val(),
			text_align: $("#simple_text_align").val(),
			color: $("#simple_color").val(),
		}
		msg = ['command', 'simple_svg',data]
		window.socket.send(JSON.stringify(msg))
	
	delayed_update = ->
		clearTimeout(timer)
		timer = setTimeout(request_svg, 500)
	
	
	$("[data-simple-field]").on input: ->
		$(".updating_preview").show()
		delayed_update()
	
	$("[data-simple-field]").on change: ->
		$(".updating_preview").show()
		delayed_update()
	
	if $("[data-simple-field]").length
		$(".updating_preview").show()
		window.socket.addEventListener "open", (e) =>
			delayed_update()