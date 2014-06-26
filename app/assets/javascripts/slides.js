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
