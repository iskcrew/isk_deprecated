# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class Display < ActiveRecord::Base
	
	
	before_save do
		if self.manual
			self.do_overrides = false
		end
		return true
	end
	
	after_save do |display|
		display.display_state.save if display.display_state.changed?
	end
	
	before_create do
		ds = DisplayState.new
		self.display_state = ds
		ds.save!
	end
	
	belongs_to :presentation
	has_one :display_state
	has_one :current_group, through: :display_state
	has_one :current_slide, through: :display_state
	has_many :override_queues, :order => :position
	has_many :display_counts
	has_and_belongs_to_many :authorized_users, :class_name => 'User'
	
	validates :name, :uniqueness => true, :presence => true, :length => { :maximum => 50 }
	validates :manual, :inclusion => { :in => [true, false] }
	
	
	
	Timeout = 5 #minutes

	include ModelAuthorization
	
	attr_accessible :name, :presentation_id, :monitor, :manual, :do_overrides
	
	delegate :last_contact_at, :last_contact_at=,									to: :display_state, allow_nil: true
	delegate :last_hello, :last_hello=,											to: :display_state, allow_nil: true
	delegate :websocket_connection_id, :websocket_connection_id=, to: :display_state, allow_nil: true
	delegate :current_slide_id, :current_slide_id=,								to: :display_state, allow_nil: true
	delegate :current_group_id, :current_group_id=,								to: :display_state, allow_nil: true
	delegate :ip, :ip=,																						to: :display_state, allow_nil: true
	delegate :monitor,:monitor=,																	to: :display_state, allow_nil: true
	delegate :updated_at, to: :display_state, prefix: :state
	
	
	def websocket_channel
		return "display_" + self.id.to_s
	end
	
	def displays
		return [self]
	end
	
	#Adds a slide to override queue for the display
	def add_to_override(slide, duration)
		oq = self.override_queues.new
		oq.duration = duration
		oq.slide = slide
		self.touch
		oq.save!
	end
	
	#Either creates a new display with given name or returns exsisting display
	def self.hello(display_name, display_ip, connection_id = nil)
		display = Display.where(:name => display_name).first_or_initialize
		display.ip = display_ip
		display.websocket_connection_id = connection_id 
		display.last_contact_at = Time.now
		display.last_hello = Time.now
		display.save!
		return display
	end
	
	#Remove shown slide from override
	def override_shown(override_id, connection_id = nil)
		self.transaction do
			oq = self.override_queues.find(override_id)
			self.last_contact_at = Time.now
			self.websocket_connection_id = connection_id
			oq.destroy
			self.save!
		end
	end
	
	#Set the current group and slide for the display and log the slide as shown
	def set_current_slide(group_id, slide_id, connection_id = nil)
		self.transaction do
			if group_id != -1
				self.current_group = self.presentation.groups.find(group_id)
			else
				self.current_group_id = -1
			end
			s = Slide.find(slide_id)
			self.current_slide = s
			self.last_contact_at = Time.now
			self.websocket_connection_id = connection_id
			s.shown_on(self.id)
			self.save!
		end
	end

	#Relation for all monitored displays that are more than Timeout minutes late
	def self.late
		Display.joins(:display_state).where('display_states.monitor = ? AND last_contact_at < ?', true, Timeout.minutes.ago)
	end
	
	#Is this display more than Timeout minutes late?
	def late?
		if self.last_contact_at
			return Time.diff(Time.now, self.last_contact_at,'%m')[:diff].to_i > Timeout
		else
			return false
		end
	end
	
	#Returns the time between the last hello and last contact
	#Since the first thing a display does is to say hello this
	#gives the time since last display reboot
	def uptime
		return nil unless self.last_hello && self.last_contact_at
		
		return Time.diff(self.last_hello, self.last_contact_at, '%h:%m:%s')[:diff]
	end
	
	#Return a hash containing all associated data, including the slides
	#in the presentation.
	def to_hash
		h = Hash.new
		#Legacy stuff, updated at used to get touched when anything happened
		if self.state_updated_at > self.updated_at
			h[:updated_at] = self.state_updated_at.to_i
		else
			h[:updated_at] = self.updated_at.to_i
		end
			
		h[:metadata_updated_at] = self.updated_at.to_i
		h[:state_updated_at] = self.state_updated_at.to_i
		h[:id] = self.id
		h[:name] = self.name
		h[:last_contact_at] = self.last_contact_at.to_i
		h[:manual] = self.manual
		h[:current_slide_id] = self.current_slide_id
		h[:current_group_id] = self.current_group_id
		h[:created_at] = self.created_at.to_i
		h[:presentation] = self.presentation ? self.presentation.to_hash : Hash.new
		q = Array.new
		if self.do_overrides
			self.override_queues.each do |oq|
				q << oq.to_hash
			end
		end
		h[:override_queue] = q
		return h
	end
	

end
