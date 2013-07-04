class Schedule < ActiveRecord::Base
  attr_accessible :name
  
  has_many :schedule_events
  belongs_to :event
  
  
  
end
