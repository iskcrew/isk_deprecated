//Korvataan puuttuvat previkat oikeilla kunhan ne valmistuvat
var previewTimer = $.timer(function() {
	$('[data-preview-url]').each(function(index, element) {
		$.ajax({
			type: "GET",
			url: $(this).attr('data-preview-url'),
			dataType: 'script'
		});
	});
	if ($('[data-preview-url]').length == 0) previewTimer.stop();
}, 2000, true);


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