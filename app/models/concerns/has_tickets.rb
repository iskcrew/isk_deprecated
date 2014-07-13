#
#  has_tickets.rb
#  isk
#
#  Created by Vesa-Pekka Palmu on 2014-07-13.
#  Copyright 2014 Vesa-Pekka Palmu. All rights reserved.
#
# A general module for all models that support opening tickets on them

module	HasTickets
	extend ActiveSupport::Concern
	
	included do
		has_many :tickets, as: :about
	end
	
	# Define class methods for the model including this
	module ClassMethods
		
	end
	
end