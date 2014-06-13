# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module GroupsHelper
	def group_cache_key(group)
		group.cache_key + current_user.cache_key
	end
	
  def group_link_tag(g)
    html = 'Group:' 
    html << link_to(g.name, {:controller => :groups, :action => :show, :id => g.id}, {:name => 'group_' + g.id.to_s} )
    html << " Slides:" << g.slides.published.count.to_s << '/' << g.slides.count.to_s
    return html.html_safe
  end
	
end
