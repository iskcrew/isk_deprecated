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
		slide = (group, slide) ->
			gs_id="#{group.id}_#{slide.id}"
			s=$('<div><h2 class="slideheader">'+slide?.name+'</h2></div>')
			s.attr {id: "slide"+gs_id}
			s.addClass 'slide'

			img=$('<img/>')
			img.attr { 
				id: "img"+gs_id,
				src: "/slides/#{slide?.id}/thumb?t=#{slide?.images_updated_at}"
				}
			delete group.slides
			img.data 'group', group
			img.data 'slide', slide
			img.bind 'click', send_goto_slide
			s.append img
			
		group = (group) ->
			g=$('<div/>')
			g.attr {id: "group"+group.id}
			g.addClass "group"
			g.append $('<h1/>').text group.name
			g.append slide group, s for s in group?.slides
		
		elems=$('<div><h1>Display: '+display.name+' Presentation: '+display.presentation.name+'</h1></div>')
		elems.append group g for g in display?.presentation?.groups

		id=root.find('.active')?.id
		if id then elems.find('#'+id).addClass('active')
		root.html(elems)

	handle_current_slide = (d) ->
		gs_id="#{d?.group_id}_#{d?.slide_id}"
		console.log "received current_slide "+gs_id
		root.find('.active').removeClass 'active'
		active = root.find('#img'+gs_id)
		active.addClass 'active'
		
		img=$('<img/>')
		img.attr { 
			id: "img"+gs_id,
			src: "/slides/#{d?.slide_id}/preview"
			}
		preview.html img
		
	send_previous_slide = (event) ->
		console.log 'Sending iskdpy.goto_slide slide=previous'	
		event.preventDefault()
		d=$(event.target).data()
		data = {
			slide: 'previous',
			display_id: d.id
			}
		dispatcher.trigger 'iskdpy.goto_slide', data
        
	send_next_slide = (event) ->
		console.log "Sending iskdpy.goto_slide slide=next"
		event.preventDefault()
		d=$(event.target).data()
		data = {
			slide: 'next',
			display_id: d.id
			}
		dispatcher.trigger 'iskdpy.goto_slide', data
	
	send_goto_slide = (event) ->
		d=$(event.target).data()
		data = { 
			display_id: display_id,
			slide_id: d.slide.id,
			group_id: d.group.id
			}
		console.log data
		dispatcher.trigger 'iskdpy.goto_slide', data

	dispatcher=null
	connect = ->
		dispatcher = new WebSocketRails(window.location.host  + '/websocket')
		dispatcher.on_open = ->
			dispatcher.trigger 'iskdpy.display_data', display_id
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
	

