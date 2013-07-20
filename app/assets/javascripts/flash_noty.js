$(document).ready(function() {
	$('div.flash > div.error').each(function() {
		$(this).hide();
		if (this.textContent) {
			var errors = $('div.flash').first().noty({text: this.textContent, type: 'error'});
		}
	});


	$('div.flash > div.notice').each(function() {
		$(this).hide();
		if (this.textContent) {
			var information = $('div.flash').noty({
				text: this.textContent, 
				type: 'information',
				timeout: 10000 //10s
			});
		};
	});

});