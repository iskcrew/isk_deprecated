#
#  slides.js.coffee
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-06-26.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

$ ->
	scrollToAnchor = (aid) ->
		aTag = $("a[name='#{aid}']")
		$('html,body').animate({scrollTop: aTag.offset().top},200)
	
	handle_group_click = (e) ->
		e.preventDefault()
		full_url = this.href
		
		# split the url by # and get the anchor target name - home in mysitecom/index.htm#home
		parts = full_url.split("#")
		target = parts[1]
		# Scroll to anchor from the clicked link
		scrollToAnchor(target)
	
	$(".group_link").click( handle_group_click )