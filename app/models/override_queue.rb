class OverrideQueue < ActiveRecord::Base
  belongs_to :display
  belongs_to :slide

  validates :duration, :numericality => {:only_integer => true}
  #TODO: varmista että presis ja slide on olemassa
  
  
  acts_as_list :scope => :display_id
  
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
