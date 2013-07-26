class Schedule < ActiveRecord::Base
  attr_accessible :name, :up_next, :max_slides, :min_events_on_next_day, :schedule_events_attributes
  
  has_many :schedule_events
  belongs_to :event
  belongs_to :slidegroup, :class_name => 'MasterGroup'
  belongs_to :up_next_group, :class_name => 'MasterGroup'
  
  accepts_nested_attributes_for :schedule_events
  
  after_create do |schedule|
    slidegroup = MasterGroup.create(:name => ("Slides for schedule: " + schedule.name), :event_id => Event.current.id)
    up_next_group = MasterGroup.create(:name => ('Next up on schedule: ' + schedule.name), :event_id => Event.current.id)
    
    schedule.slidegroup = slidegroup
    schedule.up_next_group = up_next_group
    schedule.save!
  end
  
end
