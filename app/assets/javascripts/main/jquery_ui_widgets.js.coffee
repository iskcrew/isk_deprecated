# 
#  jquery_ui_widgets.js.coffee
#  isk
#  
#  Created by Vesa-Pekka Palmu on 2014-06-16.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
# 
# Initialize various jquery-ui widgets, like tooltips, spinners and tabs

$ ->
	$( ".duration_spinner" ).spinner({ min: 30, incremental: false, step: 30 })
	$( "#tabs" ).tabs()
	$( "#accordion" ).accordion()
	$( ".accordion" ).accordion( heightStyle: "content", collapsible: true)
