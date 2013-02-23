class SlideTemplate < ActiveRecord::Base
  
  
  
  #TODO: jotenkin tänne mukaan sliden kuvajutut
  
  attr_accessible :name, :description
  
  FilePath = Rails.root.join('data','templates')
  EmptySVG = FilePath.join('empty.svg')

  SimpleSVG = FilePath.join('simple.svg')
  
  def svg_filename
    unless new_record?
      return FilePath.join('template_' << self.id.to_s << '.svg')
    else
      return nil
    end
  end
  
  def destroy
    if File.exists?(self.svg_filename)
      File.delete(self.svg_filename)
    end
    super
  end
  
end
