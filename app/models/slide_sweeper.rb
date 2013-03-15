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
    expire_fragment(:controller => :groups, :action => :show, :id => slide.master_group.id)
  end
end