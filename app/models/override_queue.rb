# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class OverrideQueue < ActiveRecord::Base
  belongs_to :display, touch: true
  belongs_to :slide

  validates :duration, :numericality => {:only_integer => true}
  #TODO: varmista että presis ja slide on olemassa
	
  
  sortable :scope => :display_id
  
  def to_hash
    h = self.slide.to_hash(self.duration)
    h[:override_queue_id] = self.id
    
    return h
  end
  
  #Used by the websocket notification observer to avoid special cases
  def displays
    return [self.display]
  end
  
end
