class DisplayState < ActiveRecord::Base
	belongs_to :display
  belongs_to :current_group, class_name: "Group"
  belongs_to :current_slide, class_name: "Slide"
	
	validates :ip, length: { maximum: 20 }, presence: true
	validates :monitor, inclusion: { in: [true, false] }
	validates :current_slide_id, :current_group_id, numericality: {only_integer: true}, allow_nil: true
	validates :status, presence: true, inclusion: {in: ['disconnected', 'running', 'error']}
	
	# Send websocket messages on create and update
	include WebsocketMessages
	
	before_validation do
		self.ip = 'UNKNOWN' if self.ip.blank?
	end
	
	def displays
		[]
	end
	
end
