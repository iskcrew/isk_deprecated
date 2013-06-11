class Event < ActiveRecord::Base
  attr_accessible :name
  
  before_save :set_current_event
  
  has_many :master_groups
  
  def self.current
    self.where(:current => true).first!
  end
  
  private
  
  def set_current_event
    if self.current
      Event.update_all :current => false
    end
  end
  
end
