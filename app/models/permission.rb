class Permission < ActiveRecord::Base
  
	belongs_to :user, touch: true
	belongs_to :role
	belongs_to :slide
	belongs_to :master_group
	belongs_to :presentation
	belongs_to :display
	
	def cache_tag
		'permission_' + self.id.to_s
	end

end
