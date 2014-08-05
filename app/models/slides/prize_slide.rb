#
#  prize_slide.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-08-02.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#

class PrizeSlide < TemplateSlide
	TypeString = "prize"
	
	# FIXME: PROPER CONFIGURATION
	after_initialize do
		self.template = SlideTemplate.last
	end
end