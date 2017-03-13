# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

# Per object permissions
class PermissionsController < ApplicationController
  # Grant permissions to object for user
  def create
    object = target_object
    user = User.find(params[:grant][:user_id])
    object.authorized_users << user
    redirect_to :back
  end

  # Remove permissions on object from user
  def destroy
    object = target_object
    user = User.find(params[:user_id])
    object.authorized_users.delete(user)
    redirect_to :back
  end

private

  # Extract the target object from parameters and check for access
  def target_object
    # Find out what object we are modifying
    if params[:slide_id].present?
      object = Slide.find(params[:slide_id])
    elsif params[:group_id].present?
      object = MasterGroup.find(params[:group_id])
    elsif params[:display_id].present?
      object = Display.find(params[:display_id])
    elsif params[:presentation_id].present?
      object = Presentation.find(params[:presentation_id])
    else
      raise ArgumentError, "Unexpected parameters #{params}"
    end

    # Check that current user modify the ACL for this object
    unless object.admin? current_user
      raise ApplicationController::PermissionDenied
    end

    object
  end
end
