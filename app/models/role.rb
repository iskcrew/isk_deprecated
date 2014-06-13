# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

class Role < ActiveRecord::Base
	has_many :permissions
	has_many :users, through: :permissions, source: :user
	
end
