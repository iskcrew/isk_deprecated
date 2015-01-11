# ISK - A web controllable slideshow system
#
# This module is a work-around for websocket-rails issue #228, see:
# https://github.com/websocket-rails/websocket-rails/issues/228
# With rails 4.1 websocket-rails isn't clearing the query cache between
# different events on the same connection.
#
# This module creates a before-filter that simply clears the query cache.
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module  ClearQueryCache
	
	extend ActiveSupport::Concern
	
	
	included do
		# Register callbacks on the model we are included on

		before_action :clear_query_cache
	end

	private def clear_query_cache
		ActiveRecord::Base.connection.clear_query_cache
		return true
	end

end