#
# tubesock.js.coffee
#  
# Update the html views via websocket messages
#
# Created by Vesa-Pekka Palmu on 2014-07-06.
# Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	update_slide = (slide) ->
		# Check if the page contains this slide
		if ($('div#slide_' + slide.id).length == 0) then return
		
		console.log('Updating slide data: ' + window.location.protocol + "/slides/" + slide.id)
		
		# Update it via ajax
		$.ajax({
			type: "GET",
			url: window.location.origin + "/slides/" + slide.id,
			dataType: 'script'
		})
	
	update_slide_image = (slide) ->
		console.log('Updating slide images for slide id: ' + slide.id);
		$('img#slide_full_' + slide.id).each (index, element) ->
			console.log(' >Found full size images..')
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/full?t=' + slide.images_updated_at)
		
		$('img#slide_preview_' + slide.id).each (index, element) ->
			console.log(' >Found preview images..')
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/preview?t=' + slide.images_updated_at)
		
		$('img#slide_thumb_' + slide.id).each (index, element) ->
			console.log(' >Found thumbnails..')
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/thumb?t=' + slide.images_updated_at)
	
	update_display = (display) ->
			if ($('#display_' + display.id).length == 0) then return
			console.log('Updating display id: ' + display.id)
			
			$.ajax({
				type: "GET",
				url: window.location.origin + "/displays/" + display.id,
				dataType: 'script'
			})
	
	update_display_state = (display_state) ->
			console.log('New display state for display: ' + display_state.display_id);
			display = {id: display_state.display_id}
			update_display(display)
	
	update_tickets = (ticket) ->
		console.log 'Updating ticket counts'
		$.ajax({
			type: "GET",
			url: "/tickets",
			dataType: 'script'
		})
	
	popup_connection_lost = ->
		confirm_reconnect = ->
			if confirm("Websocket connection lost. Try to reconnect?") then initialize_websocket()
		timer = setTimeout( confirm_reconnect, 5000 )
	
	initialize_websocket = ->
		window.socket = new WebSocket "ws://#{window.location.host}/isk_general"
		window.socket.onclose = (event) -> 
			popup_connection_lost()
		window.socket.onmessage = (event) ->
			if event.data.length
				message = JSON.parse(event.data)
				switch message[0]
					when 'slide'
						update_slide_image(message[2])
						update_slide(message[2])
					when 'display'
						update_display(message[2])
					when 'display_state'
						update_display_state(message[2])
	
	initialize_websocket()
