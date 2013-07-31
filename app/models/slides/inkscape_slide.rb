class InkscapeSlide < Slide
  
  TypeString = 'inkscape'
  
  EmptySVG = Rails.root.join('data','templates', 'inkscape_empty.svg')
  
  InkscapeFragment = Rails.root.join('data','templates', 'inkscape_settings_fragment.xml')
  
	before_create do |slide|
		slide.is_svg = true
		return true
	end
	
  def self.copy!(s)
    Slide.transaction do 
      orig_id = s.id
      
      ink = s.dup
      ink.save!
      ink.reload
      
      FileUtils.copy(s.svg_filename, ink.svg_filename)
      
      ink.to_inkscape_slide!
      
      ink = InkscapeSlide.find(ink.id)
      
      s = Slide.find(orig_id)
      s.replacement_id = ink.id
      
      return ink
      
    end
  end
  
	def self.create_from_simple(simple_slide)
		self.create_from_svg(simple_slide)
	end
	
  def self.create_from_svg(simple_slide)
    return nil unless simple_slide.is_a? SvgSlide
    
    ink = InkscapeSlide.new
    
    ink.name = simple_slide.name + " (converted)"
    ink.ready = false
    ink.save!
    
    FileUtils.copy(simple_slide.svg_filename, ink.svg_filename)
    
    ink.send :inkscape_modifications
    ink.update_metadata!
    
    ink.delay.generate_images
    
    return ink
    
  end
  
  def update_metadata!
    svg = REXML::Document.new(File.read(self.svg_filename))
    
    svg = metadata_contents(svg)
  
    svg_data = String.new
    
    svg.write svg_data
    
    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end
  end
  
  protected
  
  def rsvg_command(type)
    command = 'cd ' << FilePath.to_s << ' && inkscape'
    
    if type == :full
      command << ' -w ' << Slide::FullWidth.to_s
      command << ' -h ' << Slide::FullHeight.to_s
      command << ' -e ' << self.full_filename.to_s
      command << ' ' << self.svg_filename.to_s
    end
    
    return command
  end  
	
	
	
  def metadata_contents(svg = self.svg_data)
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
  
  def inkscape_modifications
    svg = REXML::Document.new(self.svg_data)
    
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
    
    svg_data = svg.to_s
    svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')
    
    self.svg_data = svg_data
  end
  
  
end
