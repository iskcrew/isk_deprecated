#
#  monitor.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-03.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	if !$("div#monitor_settings").length then return
	
	date_string = ->
		d = new Date();
		return "#{d.getHours()}:#{d.getMinutes()}"
	
	speak_message = (message) ->
		msg = new SpeechSynthesisUtterance()
		msg.lang = 'en-US'
		msg.text = message
		
		# Bling sound before the message is spoken
		bling = new Audio('/bling.wav')
		bling.volume = 0.6
		bling.addEventListener 'ended', ->
			speechSynthesis.speak(msg)
		bling.play()
	
	insert_message = (object, msg, href) ->
		link = $('<a />')
		link.attr {
			href: href
			target: '_blank'
		}
		link.append "#{date_string()} #{msg}"
		html = $('<div />')
		html.append link
		# Add a list of changes done
		if object.changes?
			html.append "<ul>"
			$.each object.changes, (k, v) ->
				# Do not print the timestamps
				unless (k == 'updated_at') or (k == 'created_at')
					html.append "<li>#{k} has been changed to #{v}."
			console.log object.changes
			html.append "</ul>"
		$('#monitor_messages').prepend(html)
	
	notify_display = (display) ->
		msg = "Display with name #{display.name} updated"
		if $('#monitor_display_' + display.id).prop('checked')
			speak_message(msg)
		insert_message display, msg, "/displays/#{display.id}"
	
	notify_ticket_update = (ticket) ->
		console.log ticket
		msg = "Ticket with name #{ticket.name} updated"
		if $('#tickets_update').prop('checked')
			speak_message(msg)
		insert_message ticket, msg, "/tickets/#{ticket.id}"
	
	notify_ticket_create = (ticket) ->
		msg = "Ticket with name #{ticket.name} created"
		if $('#tickets_create').prop('checked')
			speak_message(msg)
		insert_message ticket, msg, "/tickets/#{ticket.id}"
		
	tickets = window.dispatcher.subscribe 'ticket'
	tickets.bind 'update', notify_ticket_update
	tickets.bind 'create', notify_ticket_create
	
	displays = window.dispatcher.subscribe 'display'
	displays.bind 'update', notify_display
	
	speak_message 'ISK Monitoring active'
	
	# Hide the compatibility warning
	$('#ttp_compatibility').hide()