#
#  tickets.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-27.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	check_open_tickets = ->
		console.log 'Checking open tickets'
		$.ajax({
			type: "GET",
			url: "/tickets",
			dataType: 'script'
		})
	
	# Check open tickets every 30 seconds, keep repeating
	timer = $.timer( check_open_tickets, 30 * 1000, true)
	
	# Also run the check at page load
	check_open_tickets()