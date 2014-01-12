# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


class Slide < ActiveRecord::Base
	require 'rexml/document'
 
	before_create do |s|
		if s.master_group.blank?
			s.master_group_id = Event.current.ungrouped.id
		end
		return true
	end
  
	after_create do |s|
		s.update_column :filename, "slide_" + s.id.to_s
    
		if @_svg_data
			s.send(:write_svg_data)
		end
    
	end
  
  
    
	belongs_to :replacement, :class_name => "Slide", :foreign_key => "replacement_id"
	belongs_to :master_group, :touch => true
	has_many :display_counts
	has_and_belongs_to_many :authorized_users, :class_name => 'User'

	validates :name, :presence => true, :length => { :maximum => 100 }
	validates :duration, :presence => true, :numericality => {:only_integer => true, :greater_than_or_equal_to => -1}
  
	attr_accessible :name, :show_clock, :description, :public, :duration
  
	scope :public, where(:public => true)
	scope :hidden, where(:public => false)
	scope :current, where(:deleted => false).where(:replacement_id => nil)
	scope :thrashed, where('replacement_id is not null OR deleted = ?', true)
  
	sortable :scope => :master_group_id
  
	
	
	Host = 'http://isk:Kissa@isk0.asm.fi'
  
	FullWidth = 1280
	FullHeight = 720
  
	PreviewWidth = 400
	PreviewHeight = 225
  
	ThumbWidth = 128
	ThumbHeight = 72

	TypeString = 'image'

	FilePath = Rails.root.join('data','slides')

	UsePresentationDelay = -1 #Set duration to this to use presentation setting
	

	include ModelAuthorization
  
  
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
		Slide.transaction do
			new_slide.save!
      
			FileUtils.copy(self.svg_filename, new_slide.svg_filename) if self.is_svg?
			FileUtils.copy(self.original_filename, new_slide.original_filename) unless self.is_svg?
			if self.ready
				FileUtils.copy(self.preview_filename, new_slide.preview_filename)
				FileUtils.copy(self.full_filename, new_slide.full_filename)
			end
		end
		return new_slide
	end
  
	def presentations
		Presentation.includes(:displays).joins(:groups => {:master_group => :slides}).where(:slides => {:id => self.id}).uniq
	end
  
	def displays
		displays_via_presentation = Display.joins(:presentation => {:groups => {:master_group => :slides}}).where(:slides => {:id => self.id}).uniq
		return displays_via_presentation.all | override.all
	end
  
	def override
		Display.joins(:override_queues => :slide).where(:slides => {:id => self.id}).uniq
	end
  
	#TODO durationille jotain
	def to_hash(dur = 20)
		hash = Hash.new
		hash[:id] = self.id
		hash[:name] = self.name
		hash[:master_group] = self.master_group_id
		hash[:group] = self.presentation_group_id if attribute_present? :presentation_group_id
		hash[:position] = self.position
		hash[:ready] = self.ready
		hash[:deleted] = self.deleted
		hash[:created_at] = self.created_at.to_i
		hash[:updated_at] = self.updated_at.to_i
		if self.duration == -1
			#Use presentation duration
			hash[:duration] = dur
		else
			#Special duration defined for this slide
			hash[:duration] = self.duration
		end
			
		hash[:images_updated_at] = self.images_updated_at.to_i
		hash[:effect] = 0
		hash[:show_clock] = self.show_clock
		hash[:type] = self.is_a?(VideoSlide) ? 'video' : 'image'
		return hash
	end
  
	#Tätä käytetään html:ssa luomaan ikonit eri slidetyypeille
	def type_str
		self.class::TypeString
	end
      
	def grouped?
		self[:master_group_id] != Event.current.ungrouped.id
	end
  
	def replaced?
		!self.replacement.nil?
	end
  
	def is_svg?
		self.is_svg
	end
  
	#Luetaan svg-data ja pistetään se muistiin kakkuun siltä varalta että tarvitaan uusiksi
	def svg_data
		return @_svg_data if (@_svg_data or self.new_record?)
    
		
		@_svg_data = File.read(self.svg_filename) if File.exists?(self.svg_filename)
    
		return @_svg_data
	end
  
	def needs_images?
		return @_needs_images ||= false
	end
  
	#Kirjoitetaan uusi svg-data tiedostoon ja merkitään kelmun kuva epäkelvoksi
	#Ei tehdä mitään jos uusi svg on sama kuin vanha, tällä säästetään vähän kuvien
	#paistamista uusiksi jos simple-slidessä muutetaan vain metatietoja
	def svg_data=(svg)
		#Simple-editin taustat on sidottu webbiserverin roottiin
		svg.gsub!('href="/backgrounds', 'href="backgrounds')
		if self.svg_data != svg
      
			@_svg_data = svg
			write_svg_data
    
			self.ready = false
			@_needs_images = true
		end
	end
  
	
	def replace!(slide)
		Slide.transaction do
			self.replacement = slide
			slide.position = self.position
			slide.master_group = self.master_group
			slide.save!
			self.destroy
		end
	end
	
	#Paistetaan kelmusta kuvat ja pingataan websockettia niistä.
	def generate_images
		if self.is_svg?
			#Generoidaan svg:stä png:t rsvg:llä
			if system rsvg_command(:full)
			end
      
      
		else
			#Kelmu on kuvatiedosto, joten paistellaan vaan sopivan kokoiset kuvat  
			picture = Magick::ImageList.new(self.original_filename).first
			
			picture = picture.change_geometry!("#{Slide::FullWidth}x#{Slide::FullHeight}>") { |cols, rows, img|
				#if the cols or rows are smaller then our predefined sizes
				#build a white background and center the image in it
				if cols < Slide::FullWidth || rows < Slide::FullHeight
					#resize our image
					img.resize!(cols, rows)
					#build the black background
					bg = Magick::Image.new(Slide::FullWidth,Slide::FullHeight){self.background_color = "black"}
					#center the image on our new white background
					bg.composite(img, Magick::CenterGravity, Magick::OverCompositeOp)
 
				else
					#in the unlikely event that the new geometry cols and rows match our predefined size
					#we will not set a bg
					img.resize!(cols, rows)
				end
			}
        
			picture.write(self.full_filename)
		end
    
		#Paistetaan ImageMagickillä previkat
		picture = Magick::ImageList.new(self.full_filename).first
		
		preview_picture = picture.resize_to_fit(Slide::PreviewWidth, Slide::PreviewHeight)
		preview_picture.write(self.preview_filename)
    
		thumb_picture = picture.resize_to_fit(Slide::ThumbWidth, Slide::ThumbHeight)
		thumb_picture.write(self.thumb_filename)

		self.ready = true
		self.images_updated_at = Time.now
		self.save!
 
 	end
  
  
	def svg_filename
		FilePath.join(self.filename + '.svg')
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
  
  
	#Konvertoidaan svg-kalvo (svg-editin tuottamassa muodossa) muotoon jota inkscape tykkää syödä
	#Ilman näitä muutoksia mm. rivitys kusee inkscapessa.
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

	def updated_image_notifications
		WebsocketRails['slide'].trigger(:updated_image, self.to_hash)
	end  



  
	protected
  
	def write_svg_data
		unless self.new_record?
			File.open(self.svg_filename, 'w') do |f|
				f.write @_svg_data
			end
		end
	end
  
  
	def ensure_master_group_exists
		errors.add(:master_group_id, "^Group is invalid") if self.master_group.nil?
	end
  
  
	def rsvg_command(type)
		command = 'cd ' << FilePath.to_s << ' && rsvg-convert'
    
		if type == :full
			command << ' -w ' << Slide::FullWidth.to_s
			command << ' -h ' << Slide::FullHeight.to_s
			command << ' --base-uri ' << Slide::FilePath.to_s << '/'
			command << ' -f png'
			command << ' -o ' << self.full_filename.to_s
			command << ' ' << self.svg_filename.to_s
		end
    
		return command
	end  
  
end
