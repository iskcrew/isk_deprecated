class DisplayState < ActiveRecord::Base
  # attr_accessible :title, :body
	
	belongs_to :display
  belongs_to :current_group, :class_name => "Group"
  belongs_to :current_slide, :class_name => "Slide"
	
	validates :ip, :length => { :maximum => 12 }
	validates :monitor, :inclusion => { :in => [true, false] }
	validates :current_slide_id, :current_group_id, :numericality => {:only_integer => true}, :allow_nil => true
	
	def displays
		[]
	end
	
end
