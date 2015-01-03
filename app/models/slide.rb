# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class Slide < ActiveRecord::Base
	require 'rexml/document'
 
	after_initialize do |s|
		if s.master_group_id == nil
			s.master_group_id = Event.current.ungrouped.id
		end
		true		
	end
 
	after_create do |s|
		s.update_column :filename, "slide_" + s.id.to_s		
	end

	# Touch associated displays
	after_save :update_timestamps
		
	belongs_to :replacement, class_name: "Slide", foreign_key: "replacement_id"
	belongs_to :master_group
	has_many :display_counts
	has_one :event, through: :master_group
	has_many :presentations, -> { uniq }, through: :master_group
	
	validates :name, presence: true, length: { maximum: 100 }
	validates :duration, presence: true, numericality: {only_integer: true, greater_than_or_equal_to: -1}
	validates :master_group, presence: true
	validates :show_clock, :ready, :public, inclusion: { in: [true, false] }
	
	scope :published, -> {where(public: true)}
	scope :hidden, -> {where(public: false)}
	scope :current, -> {where(deleted: false).where(:replacement_id => nil)}
	scope :thrashed, -> {where('replacement_id is not null OR deleted = ?', true)}
	
	delegate :name, to: :master_group, prefix: :master_group 

	include RankedModel
	ranks :position, with_same: :master_group_id, class_name: 'Slide' 
	
	include HasSvgData
	
	# Send websocket messages on create and update
	include WebsocketMessages
	
	# Ticket system
	include HasTickets
	
	Host = 'http://example.com'
	TypeString = 'image'
	FilePath = Rails.root.join('data','slides')
	UsePresentationDelay = -1 #Set duration to this to use presentation setting
	
	include ModelAuthorization
	
	# Error to raise when image operation fails
	class ImageError < StandardError
		# no further implementation necessary
	end
	
	
	def self.inherited(child)
		child.instance_eval do
			def model_name
				self.base_class.model_name
			end
		end
		
		child.class_eval do
			def to_partial_path
				'slides/slide'
			end 
		end
		super
	end
	
	@_svg_data = nil	
	
	def publish
		self[:public] = true
	end
	
	def hide
		self[:public] = false
	end
	
	def grouped
		self.where('master_group_id != ?', Event.current.ungrouped.id)
	end
	
	def ungrouped
		self.where(:master_group_id => Event.current.ungrouped.id)
	end
	
	#Log that the slide has been shown on display_id just now.
	def shown_on(display_id)
		self.display_counts.create(:display_id => display_id)
	end
	
	#Create new ungrouped hidden clone of the slide
	def clone!
		new_slide = self.dup
		new_slide.public = false
		new_slide.name = self.name.last.match(/\d+/) ? self.name.next : new_slide.name << ' (clone)'
		if new_slide.name.split('(clone)').size > 2
			new_slide.name = new_slide.name.gsub('(clone)', '(badger)') + " (mushroom)"
		elsif new_slide.name.include?("(badger)") and !new_slide.name.include?('(mushroom) (mushroom)')
			new_slide.name = new_slide.name.gsub('(clone)', '(mushroom)')
		elsif new_slide.name.include?('(mushroom) (mushroom)')
			new_slide.name = new_slide.name.gsub('(clone)', '')
		end
		new_slide.save!
		FileUtils.copy(self.data_filename, new_slide.data_filename) if self.respond_to? :data_filename
		FileUtils.copy(self.svg_filename, new_slide.svg_filename) if self.is_svg?
		FileUtils.copy(self.original_filename, new_slide.original_filename) unless self.is_svg?
		if self.ready
			FileUtils.copy(self.preview_filename, new_slide.preview_filename)
			FileUtils.copy(self.full_filename, new_slide.full_filename)
			FileUtils.copy(self.thumb_filename, new_slide.thumb_filename)
		end
		return new_slide
	end
		
	def displays
		displays_via_presentation = Display.joins(:presentation => {:groups => {:master_group => :slides}}).where(:slides => {:id => self.id}).uniq
		return displays_via_presentation.to_a | override.to_a
	end
	
	def override
		Display.joins(:override_queues => :slide).where(:slides => {:id => self.id}).uniq
	end
	
	# Create a hash with the slide metadata
	# This is used for serializing the presentations mostly
	# We check if we have extra selected attributes as follows:
	# group_name - for master_group.name
	# effect_id - for master_group.effect_id
	# presentation_group_id - for the id of the Group belonging to the presentation being serialized
	def to_hash
		hash = Hash.new
		hash[:id] = self.id
		hash[:name] = self.name
		hash[:ready] = self.ready
		hash[:deleted] = self.deleted
		hash[:created_at] = self.created_at.to_i
		hash[:updated_at] = self.updated_at.to_i
		hash[:duration] = self.duration
		hash[:images_updated_at] = self.images_updated_at.to_i
		hash[:show_clock] = self.show_clock
		hash[:type] = self.is_a?(VideoSlide) ? 'video' : 'image'
		
		hash[:master_group] = self.master_group_id
		if has_attribute? :group_name
			hash[:group_name] = self.group_name
		else
			hash[:group_name] = self.master_group.name
		end		
		if has_attribute? :effect_id
			ef = self.effect_id
		else
			ef = self.master_group.effect_id
		end
		hash[:effect_id] = ef
		hash[:group] = self.presentation_group_id if has_attribute? :presentation_group_id
		
		return hash
	end
	alias_method :to_h, :to_hash
	
	# Used in various views
	def type_str
		self.class::TypeString
	end
	
	# Is this slide in a real group?
	def grouped?
		!self.master_group.is_a?(UnGroup)
	end
	
	# Has this slide been replaced by another slide?
	def replaced?
		!self.replacement.nil?
	end
	
	def is_svg?
		self.is_svg
	end
	
	# Replace this slide with another slide
	def replace!(slide)
		self.replacement = slide
		slide.position = self.position
		slide.master_group = self.master_group
		slide.save!
		self.destroy
	end
	
	# The position of this slide inside a group
	def group_position
		Slide.where(master_group_id: self.master_group_id).where("position < ?", self.position).count
	end
	
	# Generate the various different sized images from the slide master image
	# TODO: Rely more on subclasses
	def generate_images 
		generate_full_image
		generate_previews
		
		self.ready = true
		self.images_updated_at = Time.now
		self.save!
	end
	
	def thumb_filename
		FilePath.join(self.filename + '_thumb.png')
	end

	def preview_filename
		FilePath.join(self.filename + '_preview.png')
	end
	
	def full_filename
		FilePath.join(self.filename + '_full.png')
	end
	
	def original_filename
		FilePath.join(self.filename + '_original')
	end
	
	def destroy
		self.deleted = true
		self.master_group_id = Event.current.thrashed.id
		self.save!
	end
	
	def undelete
		self.deleted = false
		self.save!
	end
	
	# Convert a old legacy svg-editor slide to inkscape slide
	# FIXME: remove this and do a migration for all possibly remaining legacy slides
	def svg_edit_to_inscape!
		
		return unless self.is_svg?
		
		svg = REXML::Document.new(File.read(self.svg_filename))
		svg.elements.delete_all('//metadata')
		metadata = svg.root.add_element('metadata')
		metadata.attributes['id'] = 'metadata1'
		metadata.text = self.id.to_s

		svg.root.attributes['xmlns:sodipodi'] = 'http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd'

		svg.root.elements.each('//text') do |e|
			e.attributes['sodipodi:linespacing'] = '125%'
			e.delete_attribute 'transform'
			i = 0
			e.elements.each('//tspan') do |t|
				t.attributes['dy'] = '1em' unless i == 0
				t.attributes['sodipodi:role'] = "line"
				t.delete_attribute 'y'
				t.delete_attribute 'transform'
				i += 1
			end
		end

		bg = svg.root.elements.each("//image[@id='background_picture']") do |bg|
			bg.attributes['xlink:href'] = 'backgrounds/empty.png'
		end


		svg_data = String.new
		svg.write svg_data

		svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')

		@_svg_data = svg_data

		write_svg_data
		
	end

	# Send websocket-messages when a slides images have been updated
	def updated_image_notifications
		WebsocketRails['slide'].trigger(:updated_image, self.to_hash)
	end	 

	# Cache tag for all fragments depending on this slide
	def cache_tag
		"slide_" + self.id.to_s
	end
	
	# Cache key for info fragment with full edit priviledges
	def rw_cache_key
		self.cache_tag + "_edit"
	end
	
	# Cache key for info fragment with hide priviledge
	def hide_cache_key
		self.cache_tag + "_hide"
	end
	
	# Cache key for info fragment with no edit priviledges
	def ro_cache_key
		self.cache_tag + "_ro"
	end
		
	protected	
		
	private
	
	# The picture dimensions
	def picture_sizes
		@_picture_sizes ||= self.event.picture_sizes
	end
	
	def self.picture_sizes
		Event.current.picture_sizes
	end
	
	def resize_command(file, size)
		"convert #{self.full_filename} -resize #{size.join('x')} #{file}"
	end
	
	# Create the preview images from the full size slide image
	def generate_previews
		system resize_command(self.preview_filename, picture_sizes[:preview])
		system resize_command(self.thumb_filename, picture_sizes[:thumb])
	end
	
	def update_timestamps
		touch_by_group(self.master_group_id)
		if changed.include? 'master_group_id'
			touch_by_group(self.master_group_id_was)
		end
	end
	
	def generate_full_image
		if self.is_svg?
			system rsvg_command(:full)
		else
			# FIXME: once legacy slides get migrated to ImageSlide this is no longer needed
			picture = Magick::ImageList.new(self.original_filename).first
			
			picture = picture.change_geometry!("#{Slide::FullWidth}x#{Slide::FullHeight}>") { |cols, rows, img|
				# if the cols or rows are smaller then our predefined sizes
				# build a black background and center the image in it
				if cols < Slide::FullWidth || rows < Slide::FullHeight
					# resize our image
					img.resize!(cols, rows)
					# build the black background
					bg = Magick::Image.new(Slide::FullWidth,Slide::FullHeight){self.background_color = "black"}
					# center the image on our new white background
					bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
 
				else
					# in the unlikely event that the new geometry cols and rows match our predefined size
					# we will not set a bg
					img.resize!(cols, rows)
				end
			}
				
			picture.write(self.full_filename)
		end
	end
	
	# Generate the full size slideimage from svg with inkscape
	def inkscape_command_line
		size = picture_sizes[:full]
		command = 'cd '' && inkscape'
		command = "cd #{Slide::FilePath} && inkscape"
		
		# Export size
		command << " -w #{size.first} -h #{size.last}"
		# Export to file
		command << " -e #{self.full_filename} #{self.svg_filename}"
		# Supress std-out reporting
		command << ' >/dev/null'
		
		return command 
	end
	
	# FIXME: Migrate old legacy stuff to new ones and kill this in favor of inkscape
	def rsvg_command(type = :full)
		size = picture_sizes[:full]
		command = 'cd ' << FilePath.to_s << ' && rsvg-convert'
		
		if type == :full
			command << " -w #{size.first} -h #{size.last}"
			command << " --base-uri #{Slide::FilePath}/"
			command << ' -f png'
			command << ' -o ' << self.full_filename.to_s
			command << ' ' << self.svg_filename.to_s
		end
		
		return command
	end
	
	# We need to proganate timestamps down the presentation chain for
	# the dpy, as it updates it's data based on timestamps
	def touch_by_group(group_id)
		d = Display.joins(:presentation => :master_groups).where(master_groups: {id: group_id})
		d.update_all(updated_at: Time.now.utc)
		
		p = Presentation.joins(:master_groups).where(master_groups: {id: group_id})
		p.update_all(updated_at: Time.now.utc)
		
		MasterGroup.where(id: group_id).update_all(updated_at: Time.now.utc)
	end
	
end
