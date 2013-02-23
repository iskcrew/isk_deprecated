/*
 * ext-multiline.js
 *
 * Licensed under the Apache License, Version 2
 *
 * Copyright(c) 2011 Pavel Šmejkal
 *
 */
 
/* 
	Extension for multiline text
*/

svgEditor.addExtension("multiLine", function() {
    var selectedElements;
    var realingSpan = function(elm, align, x) {
            if (!align) {
                align = 'start';
            }
            if(!x) {
                x = $(elm).attr('x');
            }
            var spans = $(elm).find('tspan');
            if (spans.length > 1) {
                $.each(spans, function(index, span) {
                    span.setAttribute('x', x);
                });
            }
        }    
    
    var changeAnchor = function(align) {
            $.each(selectedElements, function(index, text) {
                if (text.nodeName == 'text') {
                    var old = $(text).attr('text-anchor');
                    if (old != align) {
                        var b   = svgedit.utilities.getBBox(text);
                        var x, diff;
                        $(text).attr('text-anchor', align);
                        
                        if (align == 'end') {
                            if (old == 'start') {
                                x = $(text).attr('x') + b.width;
                            } else {
                                x = $(text).attr('x') + b.width / 2;
                            }
                        } else if (align == 'start') {
                            if (old == 'end') {
                                x = $(text).attr('x') - b.width;
                            } else {
                                x = $(text).attr('x') - b.width / 2;
                            }
                        } else if (align == 'middle') {
                            if (old == 'start') {
                                x = $(text).attr('x') + b.width / 2;
                            } else {
                                x = $(text).attr('x') - b.width / 2;
                            }
                        }
                        $(text).attr('x', x);
                        realingSpan(text, align);
                    }
                }
            });
    }
        
    
		return {
			name: "MultiLine",
            svgicons: "extensions/ext-multiline-icon.xml",
			buttons: [{
				id: "text_align_left",
				type: "context",
                panel: "text_panel",
                title: "Align left",
				events: {
					'click': function() {changeAnchor('start');}
				}
			},{
				id: "text_align_center",
				type: "context",
                panel: "text_panel",
                title: "Align right",
				events: {
					'click': function() {changeAnchor('middle');}
				}
			},{
				id: "text_align_right",
				type: "context",
                panel: "text_panel",
                title: "Align middle",
				events: {
					'click': function() {changeAnchor('end');}
				}
			}],
            elementChanged : function(opts) {
                $.each(opts.elems, function(i, elm) {
                    if (elm && elm.nodeName == 'text') {
                        realingSpan(elm, $(elm).attr('text-anchor'));
                    }
                });
            },selectedChanged: function(opts) {
				selectedElements = opts.elems;
            }
		};
});
