class GroupSweeper < ActionController::Caching::Sweeper
  observe MasterGroup
  
  def after_create(group)
    expire_cache_for(group)
  end
 
  def after_update(group)
    expire_cache_for(group)
  end
 
  def after_destroy(group)
    expire_cache_for(group)
  end
 
  private
  def expire_cache_for(group)
    expire_fragment('group_links')
    
    
    expire_fragment(:controller => :groups, :action => :show, :id => group.id)
  end
end