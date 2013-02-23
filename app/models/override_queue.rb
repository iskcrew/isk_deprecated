class OverrideQueue < ActiveRecord::Base
  belongs_to :display
  belongs_to :slide
  
  acts_as_list :scope => :display_id
  
  def to_hash
    h = self.slide.to_hash(self.duration)
    h[:override_queue_id] = self.id
    
    return h
  end
end
