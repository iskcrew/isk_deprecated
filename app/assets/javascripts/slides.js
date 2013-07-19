// Päivitetään kelmulistaa automaattisesti 60s välein
var refreshTimer = $.timer(function() {
	$('[data-refresh-url]').each(function(index, element) {
		
		$.ajax({
			type: "GET",
			url: $(this).attr('data-refresh-url'),
			dataType: 'script'
		});
	});
	if ($('[data-refresh-url]').length == 0) refreshTimer.stop();
}, 300000, true);

$().ready(function() {
	var $scrollingDiv = $("#scrollingDiv");

	$(window).scroll(function(){			
		$scrollingDiv
		.stop()
		.animate({"marginTop": Math.max(($(window).scrollTop()) - 130, 0)+ "px"}, 200 );			
	});
	
	
	var dispatcher = new WebSocketRails(window.location.host + '/websocket');

	function replace_slideitem(slide) {
	  	console.log('fooo! ' + window.location.protocol + "/slides/" + slide.id);
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

	slidelist = dispatcher.subscribe('slide');
	slidelist.bind('update', replace_slideitem);
	console.log('asdasdasd!!!');
	slidelist.bind('updated_image', replace_slide_image);
	
});
	
function scrollToAnchor(aid){
    var aTag = $("a[name='"+ aid +"']");
    $('html,body').animate({scrollTop: aTag.offset().top},200);
};

jQuery(function($) {
	$(".grouplink").click(function(e) {
   		e.preventDefault();
		var full_url = this.href;

		//split the url by # and get the anchor target name - home in mysitecom/index.htm#home
		var parts = full_url.split("#");
		var target = parts[1];


		scrollToAnchor(target);
	});
});
	
jQuery(function($) {
	$( ".duration_spinner" ).spinner({ min: 30, incremental: false, step: 30 });
	$(document).tooltip({show: {duration: 1000, easing: 'easeInExpo'}});
	$( "#tabs" ).tabs();
});

