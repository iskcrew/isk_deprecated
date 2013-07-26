class Schedule < ActiveRecord::Base
	attr_accessible :name, :up_next, :max_slides, :min_events_on_next_day, :schedule_events_attributes
  
	has_many :schedule_events, :order => "at ASC"
	belongs_to :event
	belongs_to :slidegroup, :class_name => 'MasterGroup'
	belongs_to :up_next_group, :class_name => 'MasterGroup'
  
	accepts_nested_attributes_for :schedule_events
  
	TemplateFile = Rails.root.join('data', 'slides', 'schedule.svg.erb')
	EventsPerSlide = 9
	TimeTolerance = 15.years
	
	after_create do |schedule|
		slidegroup = MasterGroup.create(:name => ("Slides for schedule: " + schedule.name), :event_id => Event.current.id)
		up_next_group = MasterGroup.create(:name => ('Next up on schedule: ' + schedule.name), :event_id => Event.current.id)
    
		schedule.slidegroup = slidegroup
		schedule.up_next_group = up_next_group
		schedule.save!
	end
	
	#Generate schedule slides
	def generate_slides
		slide_template = ERB.new(File.read(TemplateFile))
		
		return paginate_events
		
	end
	
	private
	
	
	#Create an array containing items for each slide suitable for the template
	#A slide contains at most EventsPerSlide number of events in it
	#If day changes between slides a new header will be added
	#If the new day would have less than self.min_events_on_next_day events after it on the current slide
	#create a new slide.
	def paginate_events
		slide_items = Array.new
		last_date = nil
	
		self.schedule_events.each do |e|
			#Ignore events that are more than TimeTolerance in past
			unless (e.at + TimeTolerance).past?
			
				#Insert a subheader if next event is in different day
				unless (e.at.to_date === last_date)
					slide_items << {:subheader => (e.at.strftime('%A %d.%m.'))}
				end
				slide_items << {:name => e.name, :at => e.at.strftime("%H:%M")}
				last_date = e.at.to_date
			end
		end
	
		#Break the events up on slides EventsPerSlide per slide
		slides = Array.new
		this_slide = Array.new
		last_subheader = nil
	
		slide_items.each do |item|
			if item[:subheader]
				if (this_slide.size + self.min_events_on_next_day > Schedule::EventsPerSlide) 
					slides << this_slide
					this_slide = Array.new
				end
				last_subheader = item	
			elsif this_slide.empty?
				this_slide << last_subheader
			end
		
			this_slide << item
		
			if this_slide.size == Schedule::EventsPerSlide
				slides << this_slide
				this_slide = Array.new
			end			
		end
	
		slides << this_slide unless this_slide.empty?
	
		return slides
	
	end
end