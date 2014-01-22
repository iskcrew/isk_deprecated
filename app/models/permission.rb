class Permission < ActiveRecord::Base
  
	belongs_to :user
	belongs_to :role
	belongs_to :slide
	belongs_to :master_group
	belongs_to :presentation
	belongs_to :display
	
	# attr_accessible :title, :body
end
