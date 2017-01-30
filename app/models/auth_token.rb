# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2017 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class AuthToken < ActiveRecord::Base
	belongs_to :user
	validates :token, :user, presence: true
	
	# Authenticate a user with a token
	def self.authenticate(token)
		token = self.where(token: token).first
		if token
			return token.user
		else
			return nil
		end
	end
	
end
