class Permission < ActiveRecord::Base
  belongs_to :target, polymorphic: true
	belongs_to :user, touch: true
	
	def cache_tag
		'permission_' + self.id.to_s
	end

end
