class AdminController < ApplicationController
	
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
