$().ready(function() {
	
	$('#scrollingDiv').waypoint('sticky', {
		wrapper: '<div class="scrollingDiv-wrapper" />',
		stuckClass: 'stuck'
	});
	
	var dispatcher = new WebSocketRails(window.location.host + '/websocket');

	function replace_slideitem(slide) {
		console.log('Updating slide data: ' + window.location.protocol + "/slides/" + slide.id);
		
		//Tarkistetaan että onko kelmua hötömölössä ennen kuin haetaan ajaxia
		if ($('div#slide_' + slide.id).length == 0) return
		
		$.ajax({
			type: "GET",
			url: window.location.origin + "/slides/" + slide.id,
			dataType: 'script'
		});
	};

	function replace_slide_image(slide) {
		console.log('Updating slide images for slide id: ' + slide.id);
		$('img#slide_full_' + slide.id).each(function(index, element) {
			console.log(' >Found full size images..');
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/full?t=' + slide.images_updated_at);
		});
		
		$('img#slide_preview_' + slide.id).each(function(index, element) {
			console.log(' >Found preview images..');
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/preview?t=' + slide.images_updated_at);
		});
		
		$('img#slide_thumb_' + slide.id).each(function(index, element) {
			console.log(' >Found thumbnails..');
			$(element).attr("src", window.location.origin + '/slides/' + slide.id + '/thumb?t=' + slide.images_updated_at);
		});
	};

	function update_display(display) {
		console.log('Updating display id: ' + display.id);
		if ($('#display_' + display.id).length == 0) return
		
		$.ajax({
			type: "GET",
			url: window.location.origin + "/displays/" + display.id,
			dataType: 'script'
		});
	};
	
	function update_display_state(display_state) {
		console.log('New display state for display: ' + display_state.display_id);
		display = {id: display_state.display_id};
		update_display(display);
	}
	
	displays = dispatcher.subscribe('display');
	displays.bind('update', update_display);

	display_states = dispatcher.subscribe('displaystate');
	display_states.bind('update', update_display_state);

	slidelist = dispatcher.subscribe('slide');
	slidelist.bind('update', replace_slideitem);
	slidelist.bind('updated_image', replace_slide_image);
	
});
