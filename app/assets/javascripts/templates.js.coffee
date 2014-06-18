# 
#  templates.js.coffee
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-15.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 


$ ->
	update_template_slide_fields = ->
		data = {
			slide_template_id: $("select#slide_foreign_object_id").val()
		}
		$.ajax({
			type: 'GET',
			url: '/slides/new',
			dataType: 'script',
			data: data,
			success: delayed_sender
		})
			
	expire = (callback, interval) ->
		timer = null
		return ->
			clearTimeout( timer )
			timer = setTimeout( callback, interval )
		
	update_preview = ->
		got_template_svg = (task) ->
			console.log("Got new svg")
			$('#template_svg').html(task)
			$('.updating_preview').hide()
	
		ws_error = (task) ->
			alert('Error getting new SVG for preview')
		
		console.log("updating preview...")
		msg = {}
		msg["template_id"] = $('input#template_id').first().val()
		$('.template_field').each ->
			f = $(@)
			msg[f.data('elementId')] = f.val()
		console.log msg
		window.dispatcher.trigger('svg.template', msg, got_template_svg, ws_error)
	
	delayed_sender = expire(update_preview, 500)
	
	delayed_send_update = ->
		$(".updating_preview").show()
		delayed_sender()
	
	if $("select#slide_foreign_object_id").length
		update_template_slide_fields();
		$("select#slide_foreign_object_id").change(update_template_slide_fields);
	
	$('div#template_slide_form').on "input", delayed_send_update
	$('div#template_slide_form').on "change", delayed_send_update
	if $('div#template_slide_form .template_field').length
		update_preview()
