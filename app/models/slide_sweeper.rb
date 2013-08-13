# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class SlideSweeper < ActionController::Caching::Sweeper
  observe Slide
  
  def after_create(slide)
    expire_cache_for(slide)
  end
 
  def after_update(slide)
    expire_cache_for(slide)
  end
 
  def after_destroy(slide)
    expire_cache_for(slide)
  end
 
  private
  def expire_cache_for(slide)
    
    expire_fragment('group_links')
    
    expire_fragment(:controller => :slides, :action => :show, :id => slide.id, :edit => true)
    expire_fragment(:controller => :slides, :action => :show, :id => slide.id, :hide => true)
    expire_fragment(:controller => :slides, :action => :show, :id => slide.id)
  end
end