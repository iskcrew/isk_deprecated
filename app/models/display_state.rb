class DisplayState < ActiveRecord::Base
  # attr_accessible :title, :body
	
	belongs_to :display
  belongs_to :current_group, :class_name => "Group"
  belongs_to :current_slide, :class_name => "Slide"
	
	
end
