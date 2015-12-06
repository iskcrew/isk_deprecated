#
#  dpy_remote.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-02.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# Javascript for remote control of iskdpy displays via websockets
#
# We need to first request the display serialization and then build the html based on it.
# Then we need to handle the various commands and new display states arriving.

$ -> 
	# Only run the script if the remote control interface is on this page
	root=$('#display-control').first()
	if not root then return

	display_id=root.attr('data-id')
	if not display_id then return
	
	# Function to handle incoming display serialization from websockets
	handle_display = (display) ->
		console.log "received display"
		
		# Function to create the html for a single slide
		slide = (slide) ->
			# Find the slides group in the html, create it if not found
			group_finder = 'div#group_' + slide.group
			if $(group_finder).length
				g = $(group_finder).first()
			else
				# Create the group containing this slide
				g = $('<div/>')
				g.attr {id: "group_" + slide.group}
				g.addClass "group"
				g.addClass "panel"
				g.addClass "panel-primary"
				g.append $('<div class="panel-heading"/>').text slide.group_name
				root.append g
			# Append the slide to the group
			gs_id="#{slide?.group}_#{slide?.id}"
			s=$('<div><h2 class="slideheader">'+slide?.name+'</h2></div>')
			s.attr {id: "slide_"+gs_id}
			s.addClass 'slide'
			
			img=$('<img/>')
			img.attr { 
				id: "img_"+gs_id,
				src: "/slides/#{slide?.id}/thumb?t=#{slide?.images_updated_at}"
			}
			img.data 'group', slide?.group
			img.data 'slide', slide?.id
			
			# Bind clicks on the image to send_got_slide function.
			# This will instruct the display to go to this slide.
			img.bind 'click', send_goto_slide
			s.append img
			g.append s
		
		elems=$('<div><h1>Display: '+display.name+' Presentation: '+display.presentation.name+'</h1></div>')
		root.html(elems)
		
		# Iterate over all slides in the display serialization and run the slide function
		slide s for s in display?.presentation?.slides
		
		# Set the active class to the current slide for highlighting
		current = $('img#img_' + display.current_group_id + "_" + display.current_slide_id)
		if current.length
			current.first().addClass('active')		

	# Handle the current_slide websocket event, the display informs us about a slide change.
	handle_current_slide = (d) ->
		gs_id="#{d?.group_id}_#{d?.slide_id}"
		console.log "received current_slide "+gs_id
		root.find('.active').removeClass 'active'
		active = root.find('#img_'+gs_id)
		active.addClass 'active'
	
	# Send a websocket message instructing the display to go to previous slide
	send_previous_slide = (event) ->
		event.preventDefault()
		d=$('#previous').data()
		data = {
			slide: 'previous',
			display_id: d.id
			}
		console.log 'Sending iskdpy.goto_slide slide=previous, display_id=' + data.display_id
		msg = ['goto_slide', 'reserved', data]
		window.display_socket.send(JSON.stringify(msg))
	
	# Send a websocket message instructing the display to go to next slide
	send_next_slide = (event) ->
		event.preventDefault()
		d=$('#next').data()
		data = {
			slide: 'next',
			display_id: d.id
			}
		console.log 'Sending iskdpy.goto_slide slide=next, display_id=' + data.display_id
		msg = ['goto_slide', 'reserved', data]
		window.display_socket.send(JSON.stringify(msg))
	
	# Key listener, we bind the left curson key to previous slide and right cursor to next slide
	handle_keydown = (event) ->
		console.log "Got keydown: " + event.which
		if (event.which == 37) then send_previous_slide event		
		if (event.which == 39) then send_next_slide event
		
	# Send a websocket message instructing the display to go directly to a given slide.
	send_goto_slide = (event) ->
		d=$(event.target).data()
		data = { 
			display_id: display_id,
			slide_id: d.slide,
			group_id: d.group
			}
		console.log "sending goto_slide display_id:#{data.display_id}, slide_id:#{data.slide_id}, group_id:#{data.group_id}"
		msg = ['goto_slide', 'reserved', data]
		window.display_socket.send(JSON.stringify(msg))
	
	popup_connection_lost = ->
		confirm_reconnect = ->
			if confirm("Websocket connection lost. Try to reconnect?") then initialize_websocket()
		timer = setTimeout( confirm_reconnect, 5000 )
	
	initialize_websocket = ->
		url = root.attr('data-websocket-url')
		if window.location.protocol == 'https:'
			url = "wss://#{window.location.host}#{url}"
		else
			url = "ws://#{window.location.host}#{url}"
		window.display_socket = new WebSocket url
		window.display_socket.onclose = (event) -> 
			popup_connection_lost()
		window.display_socket.onmessage = (event) ->
			if event.data.length
				message = JSON.parse(event.data)
				console.log "incoming data: #{message[0]}"
				switch message[1]
					when 'data'
						handle_display(message[2])
					when 'current_slide'
						handle_current_slide(message[2])
		window.display_socket.onopen = (event) ->
			msg = ['get_data', 'reserved', {}]
			window.display_socket.send(JSON.stringify(msg))
		
	# Initialize the websocket
	initialize_websocket()
	
	# Bind the clicks on buttons to our functions
	$('#previous').bind 'click', send_previous_slide
	$('#next').bind 'click', send_next_slide
	$(window).bind 'keydown', handle_keydown
