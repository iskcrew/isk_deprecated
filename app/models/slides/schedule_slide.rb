class ScheduleSlide < Slide
  #Automatically generated schedule slide
  TypeString = 'schedule'
  
	before_create do |slide|
		slide.is_svg = true
		return true
	end
	  
end