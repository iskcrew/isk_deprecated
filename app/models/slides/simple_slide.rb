class SimpleSlide < SvgSlide
  
  TypeString = 'simple'
  
  @slidedata = nil

  DefaultSlidedata = ActiveSupport::HashWithIndifferentAccess.new(:heading => 'Slide heading', :text => 'Slide contents with <highlight>', :color => 'Red', :text_size => 48, :text_align => 'Left').freeze
  include HasSlidedata


  after_create do |s|
    s.send(:write_slidedata)
  end


  attr_accessible :name, :description, :show_clock, :slidedata, :svg_data

  def self.copy!(s)
    Slide.transaction do 
      orig_id = s.id
      
      simple = s.dup
      simple.save!
      simple.reload
      
      FileUtils.copy(s.svg_filename, simple.svg_filename)
      
      raise ApplicationController::ConvertError unless simple.to_simple_slide!
      
      simple = SimpleSlide.find(simple.id)
      
      s = Slide.find(orig_id)
      s.replacement_id = simple.id
      
      return simple
    end  
  end
  

  
  def clone!
    new_slide = super
    new_slide.slidedata = self.slidedata
    return new_slide
  end
  
    
end