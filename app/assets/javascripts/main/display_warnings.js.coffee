#
#  display_warnings.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-26.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	check_display_warnings = ->
		console.log 'Checking display warnings'
		$.ajax({
			type: "GET",
			url: "/displays",
			dataType: 'script'
		})
	
	# Check display states every 30 seconds, keep repeating
	timer = $.timer( check_display_warnings, 30 * 1000, true)
	
	# Also run the check at page load
	check_display_warnings()