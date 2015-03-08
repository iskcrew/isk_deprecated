# Simple spinner input

$ ->
	find_input = (e) ->
		$(e).parents('.spinner').find('input')
	
	increment = ->
		e = find_input(this)
		e.val( parseInt(e.val(), 10) + 1)
	
	decrement = ->
		e = find_input(this)
		e.val( parseInt(e.val(), 10) - 1)
		
	$('.spinner .btn:first-of-type').on 'click' , increment
	$('.spinner .btn:last-of-type').on 'click', decrement
