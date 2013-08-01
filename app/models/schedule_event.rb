class ScheduleEvent < ActiveRecord::Base
  attr_accessible :name, :description, :location, :at, :major
	
	belongs_to :schedule
	
	before_save do |event|
		if event.name.length > 35
			new_name = String.new
			line = String.new
			event.name.split.each do |word|
				if line.length + word.length > 30
					new_name << line << "\n"
					line = String.new
				end
				line << word + " "
			end
			new_name << line
			self.name = new_name
			self.linecount = self.name.split("\n").size
		end
		
		return true
	end
end
