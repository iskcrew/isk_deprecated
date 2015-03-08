# Simple spinner input
# FIXME: currently buttons affect all spinners on the page!

$ ->
	increment = ->
		$('.spinner input').val( parseInt($('.spinner input').val(), 10) + 1)
	
	decrement = ->
		$('.spinner input').val( parseInt($('.spinner input').val(), 10) - 1)
		
	$('.spinner .btn:first-of-type').on 'click' , increment
	$('.spinner .btn:last-of-type').on 'click', decrement
