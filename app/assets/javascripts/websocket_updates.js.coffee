#
#  websocket_updates.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-29.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	
	replace_slideitem = (slide) ->
		# Check if the page contains this slide
		if ($('div#slide_' + slide.id).length == 0) then return
		
		console.log('Updating slide data: ' + window.location.protocol + "/slides/" + slide.id)
		
		# Update it via ajax
		$.ajax({
			type: "GET",
			url: window.location.origin + "/slides/" + slide.id,
			dataType: 'script'
		})
	
	replace_slide_image = (slide) ->
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
	
	
	# Bind to websocket events
	displays = window.dispatcher.subscribe('display');
	displays.bind('update', update_display);
	
	display_states = window.dispatcher.subscribe('displaystate');
	display_states.bind('update', update_display_state);
	
	slidelist = window.dispatcher.subscribe('slide');
	slidelist.bind('update', replace_slideitem);
	slidelist.bind('updated_image', replace_slide_image);
	
	tickets = window.dispatcher.subscribe('ticket');
	tickets.bind('update', update_tickets)
	tickets.bind('create', update_tickets)
	
	# Get the initial ticket states
	update_tickets()