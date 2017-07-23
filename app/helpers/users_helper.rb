# ISK - A web controllable slideshow system
#
# Author::    Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::   Licensed under GPL v3, see LICENSE.md

module UsersHelper
  # Buttons
  def user_assign_roles_button(user)
    link_to icon("plus", "Assign roles"), roles_user_path(user), class: "btn btn-primary"
  end

  def user_edit_button(user)
    link_to edit_link_text, edit_user_path(user), class: "btn btn-primary"
  end

  def user_delete_button(user)
    options = {
      method: :delete,
      class: "btn btn-danger",
      data: { confirm: "Are you sure you want to delete this user?" }
    }
    link_to delete_link_text, user_path(user), options
  end

  def user_details_button(user)
    link_to details_link_text, user_path(user), class: "btn btn-primary"
  end

  def user_add_token_button(user)
    link_to icon("plus", "Token"), user_tokens_path(user), class: "btn btn-primary", method: :post
  end

  def user_destroy_token_button(user, token)
    link_to delete_link_text, user_token_path(user, token), class: "btn btn-primary", method: :delete
  end
end
