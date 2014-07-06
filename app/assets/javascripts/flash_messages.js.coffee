#
#  flash_messages.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-06.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# We use the 'noty' library for displaying notifications for users.
# This script takes the flash messages and converts them into notys.

$ ->
	# Errors will be displayed until user closes them
	$('div.flash > div.error').each ->
		$(this).hide()
		if (this.textContent)
			errors = $('div.flash').noty({
				text: this.textContent 
				type: 'error'
			})
	
	# Notices and warnings hide themselves after 10 seconds
	$('div.flash > div.notice').each ->
		$(this).hide();
		if (this.textContent)
			notices = $('div.flash').noty({
				text: this.textContent 
				type: 'information'
				timeout: 10000 # 10 seconds
			})
	
	$('div.flash > div.warning').each ->
		$(this).hide();
		if (this.textContent)
			warnings = $('div.flash').noty({
				text: this.textContent
				type: 'warning'
				timeout: 10000 # 10 seconds
			})