class DisplayState < ActiveRecord::Base
  # attr_accessible :title, :body
	
	belongs_to :display
  belongs_to :current_group, class_name: "Group"
  belongs_to :current_slide, class_name: "Slide"
	
	validates :ip, length: { maximum: 20 }, presence: true
	validates :monitor, inclusion: { in: [true, false] }
	validates :current_slide_id, :current_group_id, numericality: {only_integer: true}, allow_nil: true
	
	before_validation do
		self.ip = 'UNKNOWN' if self.ip.blank?
	end
	
	def displays
		[]
	end
	
end
