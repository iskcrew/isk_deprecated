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
	$('#scrolling_div').waypoint('sticky', {
	  wrapper: '<div class="scrolling_div-wrapper" />',
	  stuckClass: 'stuck'
	});	
});
	
function scrollToAnchor(aid){
    var aTag = $("a[name='"+ aid +"']");
    $('html,body').animate({scrollTop: aTag.offset().top},200);
};

jQuery(function($) {
	$(".group_link").click(function(e) {
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

 $(function() {
$( "#accordion" ).accordion();
});

function update_template_slide_fields(){
	var data = {
		slide_template_id: $("select#slide_foreign_object_id").val()
	};
	$.ajax({
		type: 'GET',
		url: '/slides/new',
		dataType: 'script',
		data: data
	});
}

//Template form stuff
$().ready(function() {
	if( $("select#slide_foreign_object_id").length )
	{
		update_template_slide_fields();
		$("select#slide_foreign_object_id").change(update_template_slide_fields);
	};
});


