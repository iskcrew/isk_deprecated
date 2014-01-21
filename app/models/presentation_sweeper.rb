# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class PresentationSweeper < ActionController::Caching::Sweeper
  observe Presentation
  
  def after_create(presentation)
    expire_cache_for(presentation)
  end
 
  def after_update(presentation)
    expire_cache_for(presentation)
  end
 
  def after_destroy(presentation)
    expire_cache_for(presentation)
  end
 
  private
  def expire_cache_for(presentation)
		Rails.logger.debug "goooo"
  	Rails.cache.delete presentation.hash_cache_name
	end
	
	
end