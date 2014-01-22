# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module GroupsHelper
	def group_cache_key(group)
		group.cache_key + current_user.cache_key
	end
end
