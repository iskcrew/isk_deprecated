# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class AdminController < ApplicationController
	before_filter :require_global_admin
	
	
	def index
		
	end
	
	def clear_cache
		cache_store.clear
		redirect_to :index
	end
	
	def regenerate_slide_images
		Slide.all.each {|s| s.delay.generate_images}
		redirect_to :index
	end
	
end
