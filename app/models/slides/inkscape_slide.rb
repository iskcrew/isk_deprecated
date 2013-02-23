class InkscapeSlide < Slide
  
  TypeString = 'inkscape'
  
  EmptySVG = Rails.root.join('data','templates', 'inkscape_empty.svg')
  
  InkscapeFragment = Rails.root.join('data','templates', 'inkscape_settings_fragment.xml')
  
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
  
  def initialize
    super
    self.is_svg = true
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
  
  
end
