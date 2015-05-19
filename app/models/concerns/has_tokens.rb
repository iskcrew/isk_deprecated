# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

module	HasTokens
	extend ActiveSupport::Concern

	included do
		has_many :tokens, as: :access
	end
	
	# Define class methods for the model including this
	module ClassMethods
    
  end
end