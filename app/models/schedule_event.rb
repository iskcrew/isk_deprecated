class ScheduleEvent < ActiveRecord::Base
  attr_accessible :name, :description, :location, :at, :major
	
	belongs_to :schedule
end
