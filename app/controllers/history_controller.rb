# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

# Get the display history for a given display or slide
# Since this controller is nested on slides and displays we
# can deal with both cases here
class HistoryController < ApplicationController
  def index
    if params[:display_id].present?
      # We show all slides shown on given display
      @display = Display.find(params[:display_id])
      @all_slides = @display.display_counts.joins(:slide)
                            .order("count_all desc")
                            .group("slides.name", "slides.id").count
      render :index_by_display
    else
      # We show when the given slide has been shown
      @slide = Slide.find(params[:slide_id])
      @displays = @slide.display_counts.joins(:display).order("count_all desc")
                        .group("displays.name", "displays.id").count
      render :index_by_slide
    end
  end

  # Show detailed information when a given slide has been shown on
  # a given display
  def show
    @display = Display.find(params[:display_id])
    @slide = Slide.find(params[:id])
    @display_counts = @display.display_counts.where(slide_id: @slide.id)
                              .order(updated_at: :asc)
  end

  # Clear the history for a given display
  def clear
    display = Display.find(params[:display_id])

    # Check for access
    raise ApplicationController::PermissionDenied unless display.admin? current_user

    display.display_counts.delete_all
    flash[:notice] = "Cleared slide history for #{display.name}."
    redirect_to display_history_index_path(display)
  end
end
