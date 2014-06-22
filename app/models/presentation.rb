# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class Presentation < ActiveRecord::Base
	# This class contains the logic for presentations
	# Presentations are made up from ordered lists
	# of master groups, containing ordered lists of slides
	

	has_many :groups, -> {order "position ASC"}
	has_many :master_groups, through: :groups
	belongs_to :effect
	belongs_to :event
	has_many :displays
	
	has_many :permissions
	has_many :authorized_users, through: :permissions, source: :user, class_name: 'User'
	
	validates :effect, presence: true
	validates :name, presence: true, length: { :maximum => 100 }
	validates :duration, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: -1}
	
	before_create do |p|
		p.event = Event.current
	end
	
	# Touch associated displays
	after_save do |p|
		p.displays.each do |d|
			d.touch
		end
	end
	
	# Module that contains our ACL logic.
	include ModelAuthorization
	
	# Shorthand for returning the count of public slides
	# in the presentation
	def total_slides
		self.public_slides.count
	end
	
	# Returns a Relation that selects all slides in this presentation in order (public or not)
	def slides
		Slide.joins(master_group: {groups: :presentation}).where(presentations: {id: self.id}).order('groups.position, slides.position')
	end
	
	# Returns a Relation with all public slides in this presentation
	# The slides are in presentation order and have the group.id selected
	# as presentation_group_id so that it is accessible in the slide objects returned.
	def public_slides
		self.slides
			.where(slides: {public: true, deleted: false, replacement_id: nil})
	end
	
	# Creates a hash of the presentation data
	# The has currently has two representations of the
	# slides in the presentation due to legacy
	def to_hash
		hash = Rails.cache.fetch hash_cache_name, :tag => "presentation_" + self.id.to_s do
			hash = Hash.new
			hash[:name] = self.name
			hash[:id] = self.id
			hash[:effect] = self.effect_id
			hash[:created_at] = self.created_at.to_i
			hash[:updated_at] = self.updated_at.to_i
			hash[:total_groups] = self.groups.count
			hash[:total_slides] = self.total_slides
			
			hash[:slides] = Array.new
			slides_for_hash.each do |slide|
				hash[:slides] << slide_hash( slide )
			end
			hash
		end
		return hash
	end
	
	# Calculate the duration of this presentation and return it in seconds.
	def duration
		default_slides_time = self.delay * self.public_slides.where(slides: {duration: Slide::UsePresentationDelay}).count
		special_slides_time = self.public_slides.where('duration != ?', Slide::UsePresentationDelay).sum('duration')
		return default_slides_time + special_slides_time
	end
	
	# Cache tag for all fragments depending on this presentation 
	def cache_tag
		"presentation_" + self.id.to_s
	end
	
	# What name to use as key for to_hash caching
	def hash_cache_name
		cache_key + "_hash"
	end
	
	# Augmented select for creating the hash serialization
	def slides_for_hash
		public_slides.select([
				'slides.*',
				'groups.id as presentation_group_id',
				'master_groups.name as group_name',
				'master_groups.effect_id as effect_id'
			])
	end
	
	private
	
	# Insert proper effect id and duration into each slides serialization.
	def slide_hash(slide)
		h = slide.to_hash
		h[:effect_id] = self.effect_id if h[:effect_id].nil?
		h[:duration] = self.delay if h[:duration] == Slide::UsePresentationDelay
		return h
	end
	
end
