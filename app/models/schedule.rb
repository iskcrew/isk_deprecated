class Schedule < ActiveRecord::Base
	attr_accessible :name, :up_next, :max_slides, :min_events_on_next_day, :schedule_events_attributes
  
	has_many :schedule_events, :order => "at ASC"
	belongs_to :event
	belongs_to :slidegroup, :class_name => 'MasterGroup'
	belongs_to :up_next_group, :class_name => 'MasterGroup'
  
	accepts_nested_attributes_for :schedule_events
  
	TemplateFile = Rails.root.join('data', 'slides', 'schedule.svg.erb')
	EventsPerSlide = 9
	TimeTolerance = 15.minutes
	
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
		
		
		slides = paginate_events
		total_slides = slides.size
		current_slide = 1
		slide_description = "Automatically generated from schedule " + self.name + " at " + (I18n.l(Time.now, :format => :short))
		
		self.slidegroup.slides.destroy_all
		
		slides.each do |s|
			if total_slides == 1
				@header = self.name
			else
				@header = self.name + ' ' + current_slide.to_s + '/' + total_slides.to_s
			end
			slide = ScheduleSlide.new
			slide.name = @header
			slide.description = slide_description
			self.slidegroup.slides << slide
			@items = s
			slide.save!
			slide.svg_data = slide_template.result(binding)
			slide.delay.generate_images
			
			current_slide += 1
		end
		
		if self.up_next and self.schedule_events.present?
			generate_up_next_slide
		end
		
		return true
	end
	
	private
	
	
	def generate_up_next_slide
		slide_template = ERB.new(File.read(TemplateFile))
		up_next_items = Array.new
		slide_description = "Next " + EventsPerSlide.to_s + " events on schedule " + self.name
		slide_name = "Up next on schedule: " + self.name
		
		self.schedule_events.where('at > ?', (Time.now - TimeTolerance)).limit(9).each do |event|
			up_next_items << {:name => event.name, :time => event.at.strftime('%H:%M')}
		end
		
		self.up_next_group.slides.destroy_all
		
		if up_next_items.size > 0
			
		
			up_next_slide = ScheduleSlide.new
			up_next_slide.name = slide_name
			up_next_slide.description = slide_description
			self.up_next_group.slides << up_next_slide
			up_next_slide.save!
			@header = "Next up: " + self.name
			@items = up_next_items
			up_next_slide.svg_data = slide_template.result(binding)
			up_next_slide.save!
			up_next_slide.delay.generate_images
		end
		
		return true
	end
	
	
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
				slide_items << {:name => e.name, :time => e.at.strftime("%H:%M")}
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