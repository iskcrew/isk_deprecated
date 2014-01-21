# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module GroupsHelper
	def group_cache_key(group)
		group.cache_key + '_user_' + current_user.id.to_s
	end
end
