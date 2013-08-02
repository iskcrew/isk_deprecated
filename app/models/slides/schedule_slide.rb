class ScheduleSlide < Slide
  #Automatically generated schedule slide
  TypeString = 'schedule'
  
	before_create do |slide|
		slide.is_svg = true
		return true
	end
	
	private
	
  def rsvg_command(type)
    command = 'cd ' << FilePath.to_s << ' && inkscape'
    
    if type == :full
      command << ' -w ' << Slide::FullWidth.to_s
      command << ' -h ' << Slide::FullHeight.to_s
      command << ' -e ' << self.full_filename.to_s
      command << ' ' << self.svg_filename.to_s
			command << ' >/dev/null'
    end
    
    return command
  end  
	
	  
end