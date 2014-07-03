#
#  monitor.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-03.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	if !$("div#monitor_settings").length then return
	
	speak_message = (message) ->
		msg = new SpeechSynthesisUtterance()
		msg.lang = 'en-US'
		msg.text = message
		speechSynthesis.speak(msg)
	
	notify_display = (display) ->
		if $('#monitor_display_' + display.id).prop('checked')
			speak_message("Display with name #{display.name} updated")
	
	notify_ticket_update = (ticket) ->
		if $('#tickets_update').prop('checked')
			speak_message("Ticket with name #{ticket.name} updated")
	
	notify_ticket_create = (ticket) ->
		if $('#tickets_create').prop('checked')
			speak_message("Ticket with name #{ticket.name} created")
	
	tickets = window.dispatcher.subscribe 'ticket'
	tickets.bind 'update', notify_ticket_update
	tickets.bind 'create', notify_ticket_create
	
	displays = window.dispatcher.subscribe 'display'
	displays.bind 'update', notify_display
	
	speak_message 'ISK Monitoring active'
	
	# Hide the compatibility warning
	$('#ttp_compatibility').hide()