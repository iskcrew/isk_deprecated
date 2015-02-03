# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class Event < ActiveRecord::Base
		
	has_many :master_groups
	has_many :presentations
	has_many :schedules
	has_many :slides, through: :master_groups
	
	serialize :config, Hash
	
	belongs_to :thrashed, class_name: 'ThrashGroup', foreign_key: 'thrashed_id'
	belongs_to :ungrouped, class_name: 'UnGroup', foreign_key: 'ungrouped_id'
	
	validates :name, uniqueness: true, presence: true
	validates :current, inclusion: { in: [true, false] }	
	validates :ungrouped, :thrashed, presence: true
	validate :ensure_one_current_event
	
	# Make sure there is only one current event
	before_save :set_current_event
	
	# Create the associated groups as needed and set their event_id
	before_validation :create_groups, on: :create
	after_create :set_group_event_ids
		
	# Default config for events
	DefaultConfig = {
		full: { # Full slide image size
			width: 1280,
			height: 720
		},
		preview: { # Preview image size
			width:  400,
			height: 225
		},
		thumb: { # Small thumbnail size
			width: 128,
			height: 72
		},
		schedules: {
			# How many events to typeset per slide
			events_per_slide: 9,
			# Show events at most this long in the past
			time_tolerance: 15.minutes,
			# ScheduleSlide config
			slides: {
				# Date subheaders
				subheader_fill: '#e2e534',
				indent: {
					time: 50,
					name: (50 + 230)
				},
				font_size: '72px',
				linespacing: '100%'
			}
		}
	}
	
	# Resolutions that are currently supported.
	# Note that the display (eg. iskdpy) also needs to support them.
	SupportedResolutions = [
		[1280, 720],
		[1920, 1080]
	]
		
	# Finds the current event
	def self.current
		self.where(:current => true).first!
	end
	
	# Regenerate slide images for all slides in this event.
	# Used after changing the slide image size.
	def generate_images!
		self.slides.each do |s|
			s.generate_images
		end
	end
	
	#### Per event configuration
	
	# Read the stored configuration. Use default if blank.
	def config
		if self[:config].blank?
			self[:config] = DefaultConfig
			return self[:config]
		else
			return DefaultConfig.merge self[:config]
		end
	end
	
	# The configuration options for the simple editor
	# FIXME: True dynamic settings!
	def simple_editor_settings
		settings = {
			heading: {
				font_size: 120,
				coordinates: [500, 130]
			},
			body: {
				margins: [550, picture_sizes[:full].first - 30],
				y_coordinate: 280
			},
			font_sizes: [48,50,60,70,80,90,100,120,160,200,300,400]
		}
		if self.picture_sizes[:full] == SupportedResolutions[1]
			settings[:font_sizes] = [80,90,100,120,160,200,300,400]
		end
		return settings
	end
	
	# Set the size for full slide pictures. Checks that the resolution is supported.
	def picture_size=(size)
		if SupportedResolutions.include? size
			cnf = config
			cnf[:full][:width] = size.first
			cnf[:full][:height] = size.last
			config = cnf
		else
			raise ArgumentError, 'Resolution not supported'
		end
	end
	
	# Returns a hash containing the set picture sizes.
	def picture_sizes
		h = Hash.new
		[:full, :preview, :thumb].each do |key|
			h[key] = [self.config[key][:width], self.config[key][:height]]
		end
		return h
	end
	
	# The filename for the background image
	# FIXME: True dynamic setting!
	def background_image
		return 'backgrounds/empty.png'
	end
	
	def prize_template
		SlideTemplate.find(self.config[:prize_template])
	end
	
	private
	
	# Update the config
	def config=(cnf)
		self[:config] = cnf
	end
	
	# Create the associated groups as needed
	def create_groups
		self.ungrouped = UnGroup.create(
			name: ('Ungrouped slides for ' + self.name)
		) if self.ungrouped.nil?
		self.thrashed = ThrashGroup.create(
			name: ('Thrashed slides for ' + self.name)
		) if self.thrashed.nil?
	end
	
	# Set the event associations on special groups
	def set_group_event_ids
		self.ungrouped.event_id = self.id
		self.ungrouped.save!
		self.thrashed.event_id = self.id
		self.thrashed.save!
	end
	
	# Callback that resets every other event to non-current when setting another as current one
	def set_current_event
		if self.current && self.changed.include?('current')
			Event.update_all :current => false
		end
	end
	
	# Validation that prevents clearing the current event -bit
	def ensure_one_current_event
		if !self.current && self.changed.include?('current')
			errors.add(:current, "^Must have one current event")
		end
	end
		
end
