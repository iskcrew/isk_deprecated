$ -> 
	preview=$('#display_preview')
	root=$('#display_control').first()
	if not root then return

	display_id=root.attr('data-id')
	if not display_id then return

	$('.display_preview').waypoint('sticky', {
	  wrapper: '<div class="display_preview_wrapper" />',
	  stuckClass: 'stuck'
	});

	handle_display = (display) ->
		console.log "received display"
		slide = (slide) ->
			
			group_finder = 'div#group_' + slide.group
			if $(group_finder).length
				g = $(group_finder).first()
			else
				g = $('<div/>')
				g.attr {id: "group_" + slide.group}
				g.addClass "group"
				g.append $('<h1/>').text slide.group_name
				root.append g
			
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
			img.bind 'click', send_goto_slide
			s.append img
			g.append s
				
		elems=$('<div><h1>Display: '+display.name+' Presentation: '+display.presentation.name+'</h1></div>')
		root.html(elems)
		
		slide s for s in display?.presentation?.slides

		current = $('img#img_' + display.current_group_id + "_" + display.current_slide_id)
		if current.length
			current.first().addClass('active')		

	handle_current_slide = (d) ->
		gs_id="#{d?.group_id}_#{d?.slide_id}"
		console.log "received current_slide "+gs_id
		root.find('.active').removeClass 'active'
		active = root.find('#img_'+gs_id)
		active.addClass 'active'
		
		img=$('<img/>')
		img.attr { 
			id: "img"+gs_id,
			src: "/slides/#{d?.slide_id}/preview"
			}
		preview.html img
		
	send_previous_slide = (event) ->
		event.preventDefault()
		d=$('#previous').data()
		data = {
			slide: 'previous',
			display_id: d.id
			}
		dispatcher.trigger 'iskdpy.goto_slide', data
		console.log 'Sending iskdpy.goto_slide slide=previous, display_id=' + data.display_id
		
	send_next_slide = (event) ->
		event.preventDefault()
		d=$('#next').data()
		data = {
			slide: 'next',
			display_id: d.id
			}
		console.log 'Sending iskdpy.goto_slide slide=next, display_id=' + data.display_id
		dispatcher.trigger 'iskdpy.goto_slide', data
	
	handle_keydown = (event) ->
		console.log "Got keydown: " + event.which
		if (event.which == 37) then send_previous_slide event
		
		if (event.which == 39) then send_next_slide event
		
	
	send_goto_slide = (event) ->
		d=$(event.target).data()
		data = { 
			display_id: display_id,
			slide_id: d.slide,
			group_id: d.group
			}
		console.log data
		dispatcher.trigger 'iskdpy.goto_slide', data

	dispatcher=null
	connect = ->
		dispatcher = new WebSocketRails(window.location.host  + '/websocket')
		dispatcher.on_open = ->
			dispatcher.trigger 'iskdpy.display_data', {display_id: display_id}
				, success = (d) -> handle_display d
				, failure = (d) -> alert 'Websocket failed'
			channel=dispatcher.subscribe 'display_'+display_id
			channel.bind 'data', callback=handle_display
			channel.bind 'current_slide', callback=handle_current_slide
		dispatcher.on_close = ->
			if confirm("Connection lost. Reconnect?")
			then connect()
		dispatcher.on_error = ->
			if confirm("Connection lost. Reconnect?")
			then connect()
	connect()
	$('#previous').bind 'click', send_previous_slide
	$('#next').bind 'click', send_next_slide
	$(window).bind 'keydown', handle_keydown

