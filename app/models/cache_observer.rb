# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class CacheObserver < ActiveRecord::Observer
	observe :slide, :master_group, :presentation
	
	def after_commit(obj)
		obj.expire_cache
	end


end