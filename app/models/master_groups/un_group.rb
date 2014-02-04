# ISK - A web controllable slideshow system
#
# Group for storing trashed slides in
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class	UnGroup < MasterGroup
	belongs_to :event
	
  has_many :slides, foreign_key: :master_group_id, order: 'position ASC'
	
	after_initialize do |g|
		g.internal = true
	end

	def name
		'Thrashed slides'
	end
	
end