/*
 * ext-wheel-zoom.js
 *
 * Licensed under the Apache License, Version 2
 *
 * Copyright(c) 2011 Pavel Šmejkal
 *
 */
 
/* 
	Extension which allow zooming by Alt | Ctrl + mouse wheel 
*/

svgEditor.addExtension("mouseZoom", function() {
        $(window).mousewheel(function(e, intDelta){
            if (e.ctrlKey || e.altKey) {
                svgEditor.changeZoom(svgCanvas.getZoom() * 100 + (intDelta < 0 ? -15 : 15));
                e.preventDefault();
                e.stopPropagation();
            }
        });
		return {
			name: "MouseZoom",
			buttons: [],
			mouseDown: function() {
				if(0) {
					return {started: true};
				}
			},
			mouseUp: function(opts) {
			}
		};
});
