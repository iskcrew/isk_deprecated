# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md


module UsersHelper
	
	# Buttons
	def user_assign_roles_button(user)
		link_to icon('plus', 'Assign roles'), roles_user_path(user), class: 'button'
	end
	
	def user_edit_button(user)
		link_to icon('edit', 'Edit'), edit_user_path(user), class: 'button'
	end
	
	def user_delete_button(user)
		options = {
			method: :delete, 
			class: 'button warning',
			data: {confirm: "Are you sure you want to delete this user?"}
		}
		link_to icon('times-circle', 'Delete'), user_path(user), options 
	end
	
	def user_details_button(user)
		link_to icon('info-circle', 'Details'), user_path(user), class: 'button'
	end
end
