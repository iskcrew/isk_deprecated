class SvgSlide < Slide
  
  TypeString = 'svg-edit'

  @_svg_data = nil
#TODO: svg-datan käsittely tänne kontrollerista
  
  def initialize
    super
    self.is_svg = true
  end
    
  def to_inkscape_slide!
    return nil unless self.is_svg?
    
    svg = REXML::Document.new(File.read(self.svg_filename))
    
    svg = metadata_contents(svg)
    
    svg = inkscape_modifications(svg)
    
    svg_data = String.new
    svg.write svg_data
    
    svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')
    
    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end
    
    self.type = InkscapeSlide.model_name
    self.ready = false
    self.save!
    
    #Kuvien generointi failaa jos ei anneta oikeaa luokkaa...
    is = InkscapeSlide.find(self.id)
    is.delay.generate_images
  end


  def sanitize!
    svg = REXML::Document.new(File.read(self.svg_filename))
    
    metadata_contents(svg)
    
    svg.root.elements.each('//text') do |e|
      e.delete_attribute 'xml:space'
    end

    svg_data = String.new
    svg.write svg_data

    svg_data.gsub!('FranklinGothicHeavy', 'Franklin Gothic Heavy')

    File.open(self.svg_filename, 'w') do |f|
      f.write svg_data
    end
  end


end
