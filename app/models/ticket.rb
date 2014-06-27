class Ticket < ActiveRecord::Base
	belongs_to :event
	belongs_to :about, polymorphic: true
	
	StatusNew = 1
	StatusOpen = 2
	StatusClosed = 3
	StatusCodes = {StatusNew => 'new', StatusOpen => 'open', StatusClosed => 'closed'}
	ValidModels = [Slide, MasterGroup, Presentation]
	
	validates :name, presence: true
	validates :status, inclusion: { in: Ticket::StatusCodes }
	validates :description, presence: true
	validates :event, presence: true
	validate :check_valid_models
	
	before_validation :assign_to_current_event, on: :create
	before_update :set_as_open
	
	scope :current, -> { where(event_id: Event.current.id).order(status: :asc, updated_at: :asc) }
	scope :open, -> { where.not status: StatusCodes[:closed] }
	scope :closed, -> { where status: StatusCodes[:closed]}
	
	def status_text
		StatusCodes[self.status]
	end
	
	private
	
	# Unless the ticket status has been set specificly we will set edited tickets as 'open'
	def set_as_open
		unless self.changes.include? :status
			self.status = StatusOpen
		end
	end
	
	# Validation to check that our polymorphic association is of a valid type
	def check_valid_models
		pass = false
		
		# Having no assigned object is fine
		if self.about.blank?
			return
		end
		
		# Check that the assigned object is in the ValidModels list
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
