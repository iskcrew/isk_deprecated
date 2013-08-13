# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class DisplayCount < ActiveRecord::Base
  
  belongs_to :display
  belongs_to :slide
  
  scope :by_time, order(:modified_at => 'desc')
  
  
  
end
