class Ticket < ActiveRecord::Base
	belongs_to :event
	belongs_to :about, polymorphic: true
	
	StatusCodes = {1 => 'new', 2 => 'open', 3 => 'closed'}
	ValidModels = [Slide, MasterGroup, Presentation]
	
	validates :name, presence: true
	validates :status, inclusion: { in: Ticket::StatusCodes }
	validates :description, presence: true
	validates :event, presence: true
	validate :check_valid_models
	
	before_validation :assign_to_current_event, on: :create
	
	scope :current, -> { where event_id: Event.current.id }
	scope :open, -> { where.not status: StatusCodes[:closed] }
	scope :closed, -> { where status: StatusCodes[:closed]}
	
	private
	
	# Validation to check that our polymorphic association is of a valid type
	def check_valid_models
		pass = false
		ValidModels.each do |m|
			pass = pass ? true : self.about.is_a?(m)
		end
		errors.add(:about, "must be a valid object") unless pass
	end
	
	# Assign the created ticket to the current event
	def assign_to_current_event
		if self.event.blank?
			self.event = Event.current
		end
	end
	
end
