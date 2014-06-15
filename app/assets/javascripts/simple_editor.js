var dispatcher = new WebSocketRails(window.location.host + '/websocket');

var got_svg = function(task) { 
	console.log("Got new svg");
	$('#svg_container').html(task);
	$('.updating_preview').hide();
}

var ws_error = function(task) {
  console.log("Failed to create svg....");
}

var expire = function( callback, interval ) {
	var timer;
	return function() {
		clearTimeout( timer );
		timer = setTimeout( callback, interval );
	};
}

var updateSlide = function() {
	console.log("updating...");
	var msg = {
		simple: {
			heading: $("#simple_head").val(),
			text: $("#simple_text").val(),
			text_size: $("#simple_text_size").val(),
			text_align: $("#simple_text_align").val(),
			color: $("#simple_color").val(),
		}
	};
	dispatcher.trigger('svg.simple', msg, got_svg, ws_error);
}

var delayedUpdater = expire(updateSlide, 500);
 
$(function() {
	$("[data-simple-field]").on("input", function(){
		$(".updating_preview").show();
		delayedUpdater();
	});
	
	$("[data-simple-field]").on("change", function(){
		$(".updating_preview").show();
		delayedUpdater();
	});
});

$().ready(function() {
	if( $("[data-simple-field]").length )         // use this if you are using id to check
	{
	     updateSlide();
	}
	
});


function set_multiline_align(output, input, align) {
  if (align == "Left") {
    output.setAttributeNS(null, "x", (TEMPLATE_TEXT_X));
    output.setAttributeNS(null, "text-anchor", "start");
    input.style.textAlign = "left";
  } else if (align == "Right") {
    output.setAttributeNS(null, "x", (TEMPLATE_WIDTH - TEMPLATE_TEXT_X));
    output.setAttributeNS(null, "text-anchor", "end");
    input.style.textAlign = "right";
  } else if (align == "Centered") {
    output.setAttributeNS(null, "x", (TEMPLATE_WIDTH / 2));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  } else if (align == "Left Centered") {
    var center_width=parseInt(output.getBBox().width);
    output.setAttributeNS(null, "x", (TEMPLATE_TEXT_X + (center_width / 2)));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  } else if (align == "Right Centered") {
    var center_width=parseInt(output.getBBox().width);
    output.setAttributeNS(null, "x", ((TEMPLATE_WIDTH - TEMPLATE_TEXT_X) - (center_width / 2)));
    output.setAttributeNS(null, "text-anchor", "middle");
    input.style.textAlign = "center";
  }
}
