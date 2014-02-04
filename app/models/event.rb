# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class Event < ActiveRecord::Base
	attr_accessible :name, :current
	
	before_save :set_current_event
	
	has_many :master_groups
	
	
	belongs_to :thrashed, :class_name => 'MasterGroup', :foreign_key => 'thrashed_id'
	belongs_to :ungrouped, :class_name => 'MasterGroup', :foreign_key => 'ungrouped_id'
	
	validates :name, :uniqueness => true, :presence => true
	validates :current, :inclusion => { :in => [true, false] }	
	validate :ensure_one_current_event
	
	FilePath = Rails.root.join 'data', 'events'
	
	#Default config for events
	DefaultConfig = {
		full: { # Full slide image size
			width: 1280,
			height: 720
		},
		preview: { # Preview image size
			width: 225,
			height: 400
		},
		thumb: { # Small thumbnail size
			width: 128,
			height: 72
		},
		simple_editor: {
			heading: {
				x: 30,
				y: 100
			},
			body: {
				y: 200,
				margin_left: 30,
				margin_right: 30
			}
		},
		schedule: {
			items_per_slide: 9,
			wrap: {
				soft: 30,
				hard: 35
			},
			use_positions_from_simple: true,
			positions: {
				heading: {
					x: 30,
					y: 100,
					font_size: 80
				},
				subheader: {
					color: '#ffd700'
				},
				body: {
					x: 30,
					y: 200,
					font_size: 48
				}
			}
		}
	}
	
	#After creating a new event create the associated internal slidegroups.
	after_create do |e|
		e.ungrouped = MasterGroup.where(:name => ('Ungrouped slides for ' + e.name)).first_or_create
		e.ungrouped.internal = true
		e.ungrouped.save!
		
		e.thrashed = MasterGroup.where(:name => ('Thrashed slides for ' + e.name)).first_or_create
		e.thrashed.internal = true
		e.thrashed.save!
		
		e.master_groups << e.ungrouped
		e.master_groups << e.thrashed
		
		e.save!
	end
	
	
	#Finds the current event
	def self.current
		self.where(:current => true).first!
	end
	
	private
	
	#Callback that resets every other event to non-current when setting another as current one
	def set_current_event
		if self.current && self.changed.include?('current')
			Event.update_all :current => false
		end
	end
	
	#Validation that prevents clearing the current event -bit
	def ensure_one_current_event
		if !self.current && self.changed.include?('current')
			errors.add(:current, "^Must have one current event")
		end
	end
	
	def config
		return @_config ||= read_config
	end

	def read_config
    if !self.new_record? && File.exists?(config_filename)
      config = YAML.load(File.read(config_filename))
		end
		return config.blank? ? DefaultConfig : config
	end
	
	def write_config
		
	end
	
	def config_filename
		FilePath.join 'event_' + self.id.to_s + '_config.yml'
	end
	
end
