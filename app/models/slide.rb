class Slide < ActiveRecord::Base
  require 'rexml/document'
  
  after_create do |s|
    s.filename = "slide_" + s.id.to_s
    s.save!
  end
  
  belongs_to :replacement, :class_name => "Slide", :foreign_key => "replacement_id"
  belongs_to :master_group, :touch => true
  
  has_many :display_counts
  
  has_and_belongs_to_many :authorized_users, :class_name => 'User'
  
  
  attr_accessible :name, :show_clock, :description
  
  scope :public, where(:public => true)
  scope :hidden, where(:public => false)
  scope :current, where(:deleted => false).where(:replacement_id => nil)
  scope :grouped, where('master_group_id != ?', MasterGroup::Ungrouped_id)
  scope :ungrouped, where(:master_group_id => MasterGroup::Ungrouped_id)
  scope :thrashed, where('replacement_id is not null OR deleted = ?', true)
  
  acts_as_list :scope => :master_group
  
  Host = 'http://isk:Kissa@isk0.asm.fi'
  
  
  FullWidth = 1280
  FullHeight = 720
  PreviewWidth = 400
  PreviewHeight = 225
  
  TypeString = 'image'
  AdminRole = 'slide-admin'
  CreateRole = 'slide-create'
  
  FilePath = Rails.root.join('data','slides')
  
  @_svg_data = nil
  
  def self.can_edit(user)
    if user.has_role?(AdminRole)
      return self
    else
      self.joins(:authorized_users).where('users.id = ?', user.id)
    end
  end
  
  def clone!
    new_slide = self.dup
    new_slide.public = false
    new_slide.name = new_slide.name << ' (clone)'
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
  
  def override
    Display.joins(:override_queues => :slide).where(:slides => {:id => self.id}).uniq
  end
  
  
  def to_hash(duration)
    hash = Hash.new
    hash[:id] = self.id
    hash[:name] = self.name
    hash[:group] = self.master_group_id
    hash[:position] = self.position
    hash[:ready] = self.ready
    hash[:deleted] = self.deleted
    hash[:created_at] = self.created_at.to_i
    hash[:updated_at] = self.updated_at.to_i
    hash[:duration] = duration
    hash[:effect] = 0
    hash[:show_clock] = self.show_clock
    hash[:type] = self.is_a?(VideoSlide) ? 'video' : 'image'
    return hash
  end
  
  def type_str
    self.class::TypeString
  end
  
  
  def can_edit?(user)
    user.has_role?(AdminRole) || self.authorized_users.include?(user)
  end
  
  def can_hide?(user)
    user.has_role?('slide-hide') || can_edit?(user)
  end
    
  def grouped?
    self[:master_group_id] != MasterGroup::Ungrouped_id
  end
  
  def replaced?
    !self.replacement.nil?
  end
  
  def is_svg?
    self.is_svg
  end
  
  
  def svg_data
    return @_svg_data if @_svg_data
    
    @_svg_data = File.read(self.svg_filename)
    
    return @_svg_data
  end
  
  def svg_data=(svg)
    File.open(self.svg_filename,  'w') do |f|
      f.write svg
    end
    self.ready = false
    self.save!
  end
  
  
  #Korvataan slide kaikista paikoista uudella
  def replacement=(replacement)
    unless replacement.nil?
      self.replacement_id = replacement.id
    end   
  end
  
  def replacement_id=(rep_id)
    rep = Slide.find(rep_id)

    return false if self.replaced? || rep.replaced?
    self.transaction do
     self[:replacement_id] = rep_id
     position = self.position
     rep.master_group_id = self.master_group_id
     self.master_group_id = MasterGroup::Ungrouped_id
     self[:deleted] = true
     rep.insert_at(position)
     self.save!
     self.reload 
    end
  end
  
  def generate_images
    if self.is_svg?
      #Generoidaan svg:stä png:t rsvg:llä
      if system rsvg_command(:full)
      end
      
      picture = Magick::ImageList.new(self.full_filename)
      picture.resize_to_fit!(Slide::PreviewWidth, Slide::PreviewHeight)
      picture.write(self.preview_filename)
      
      self.ready = true
      self.save!
      self.touch
    else  
      picture = Magick::ImageList.new(self.original_filename)
      picture = picture[0]
        
      picture.resize!(Slide::FullWidth, Slide::FullHeight)
      picture.write(self.full_filename)
    
      picture.resize_to_fit!(Slide::PreviewWidth, Slide::PreviewHeight)
      picture.write(self.preview_filename)
    
      self.ready = true
      self.save!
      
      WebsocketRails[:slidelist].trigger(:updated_slideimage, self.id)
    end
  end
  
  
  def svg_filename
    FilePath.join(self.filename + '.svg')
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
    self.master_group_id = MasterGroup::Ungrouped_id
    self.save!
  end
  
  def undelete
    self.deleted = false
    self.save!
  end
  
  def master_group_id=(mg_id)
    self.transaction do
      if self[master_group_id] != mg_id
        remove_from_list if in_list?
        super(mg_id)
        assume_bottom_position unless new_record?
        self.save!
      end
    end
  end
  
  def master_group=(new_group)
    self.master_group_id = new_group.id
  end


  

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

    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end

  end


  
  private
  
  def ensure_master_group_exists
    errors.add(:master_group_id, "^Group is invalid") if self.master_group.nil?
  end
  
  
  def rsvg_command(type)
    command = 'cd ' << FilePath.to_s << ' && rsvg'
    
    if type == :preview
      command << ' -w ' << Slide::PreviewWidth.to_s
      command << ' -h ' << Slide::PreviewHeight.to_s
      command << ' ' << self.svg_filename.to_s
      command << ' ' << self.preview_filename.to_s
    else
      command << ' -w ' << Slide::FullWidth.to_s
      command << ' -h ' << Slide::FullHeight.to_s
      command << ' ' << self.svg_filename.to_s
      command << ' ' << self.full_filename.to_s
    end
    
    return command
  end
  
  def metadata_contents(svg)
    svg.elements.delete_all('//metadata')
    metadata = svg.root.add_element('metadata')
    metadata.attributes['id'] = 'metadata1'
    meta = String.new
    
    meta << self.id.to_s
    meta << '!'
    meta << Host
    
    metadata.text = meta
    
    return svg
  end
  
  def inkscape_modifications(svg)
    svg.root.add_namespace('sodipodi', "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd")
    svg.root.add_namespace('inkscape', "http://www.inkscape.org/namespaces/inkscape")
    
    #TODO named-view?
    inkscape_settings = REXML::Document.new(File.read(InkscapeSlide::InkscapeFragment))
    
    svg.root.delete_element('//sodipodi:namedview')
    svg.root[0,0] = inkscape_settings.root.elements['sodipodi:namedview']
    
    svg.root.elements.each('//text') do |e|
      e.delete_attribute 'xml:space'
      e.attributes['sodipodi:linespacing'] = '125%'
      e.elements.each('tspan') do |ts|
        ts.attributes['sodipodi:role'] = 'line'
      end
    end
    
    return svg
  end
  
    
end
