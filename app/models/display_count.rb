class DisplayCount < ActiveRecord::Base
  
  belongs_to :display
  belongs_to :slide
  
  scope :by_time, order(:modified_at => 'desc')
  
  
  
end
