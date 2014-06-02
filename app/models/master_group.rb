# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class MasterGroup < ActiveRecord::Base
	
	has_many :slides, -> {order('position ASC').where('deleted != 1') }
	has_many :groups, :dependent => :destroy
	belongs_to :effect
	belongs_to :event

	validates :name, :presence => true, :length => { :maximum => 100 }
	validates :internal, :inclusion => { :in => [true, false] }

	has_many :permissions
	has_many :authorized_users, through: :permissions, source: :user, class_name: 'User'
	
	include ModelAuthorization
	
	scope :defined_groups, -> {where(:internal => false).order('name')}
	
	before_create do |g|
		g.event = Event.current unless g.event
	end
	
	# Touch associated displays
  after_save :update_timestamps
	after_destroy :update_timestamps
	
	
	def self.ungrouped
		Event.current.ungrouped
	end
	
	def self.thrashed
		Event.current.thrashed
	end
	
	def self.current
		self.where(:event_id => Event.current.id).where(:internal => false)
	end
	
	def presentations
		Presentation.joins(:groups => :master_group).where('master_groups.id = ?', self.id).uniq.to_a
	end
	
	def displays
		Display.joins(:presentation => {:groups => :master_group}).where(:master_groups => {:id => self.id}).uniq
	end
	
	def hide_slides
		self.slides.each do |s|
			s.public = false
			s.save!
		end
	end
	
	def publish_slides
		self.slides.each do |s|
			s.public = true
			s.save!
		end
	end
	
	def public_slides
		
	end

	def destroy
		MasterGroup.transaction do
			self.slides.each do |s|
				s.master_group_id = MasterGroup::Ungrouped_id
				s.save!
			end

			super
		end
	end
	
	#Tag for all cache fragments depending on this master_group
	def cache_tag
		"master_group_" + self.id.to_s
	end
	
	private
	
	def update_timestamps
		touch_by_group(self.id)
	end
	
	# We need to proganate timestamps down the presentation chain for
	# the dpy, as it updates it's data based on timestamps
	def touch_by_group(group_id)
		d = Display.joins(:presentation => :master_groups).where(master_groups: {id: group_id})
		d.update_all("displays.updated_at = '#{Time.now.utc.to_s(:db)}'")
		
		p = Presentation.joins(:master_groups).where(master_groups: {id: group_id})
		p.update_all("presentations.updated_at = '#{Time.now.utc.to_s(:db)}'")
	end
	
	
end
