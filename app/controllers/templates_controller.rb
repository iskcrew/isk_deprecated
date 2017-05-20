# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class TemplatesController < ApplicationController
  # ACLs
  # TODO: proper filters, we require global admins in the mean time
  before_action :require_global_admin

  # List all templates for the current event
  def index
    @templates = SlideTemplate.current.all
  end

  # Show details on a given template
  def show
    @template = SlideTemplate.find(params[:id])
  end

  # form for creating a new template
  def new
    @template = SlideTemplate.new
  end

  # create a new template
  def create
    @template = SlideTemplate.new(template_params)
    @template.event = current_event

    if @template.save
      flash[:notice] = "Template created"
      redirect_to edit_template_path(@template)
    else
      flash[:error] = "Error saving template"
      render :new
    end
  end

  # Change the order of slides in the group, used with jquerry sortable widget.
  def sort
    @template = SlideTemplate.find(params[:id])
    f = @template.fields.find(params[:element_id])
    unless f
      render text: "Invalid request data", status: 400
      return
    end
    f.field_order_position = params[:element_position]
    f.save!
    @template.reload
    respond_to do |format|
      format.js { render :sortable_items }
    end
  end

  # Edit form for a template
  def edit
    @template = SlideTemplate.find(params[:id])
  end

  # Update a template
  def update
    @template = SlideTemplate.find(params[:id])

    if @template.update_attributes(update_params)
      flash[:notice] = "Template was successfully updated."
      redirect_to template_path(@template)
    else
      render action: :edit
    end
  end

  # Delete a given template and all slides based on it.
  def destroy
    template = SlideTemplate.find(params[:id])
    template.destroy
    flash[:notice] = "Template has been deleted."
    redirect_to templates_path
  end

private

  # Whitelist post parameters for update
  def update_params
    params.required(:slide_template).permit(
      :name,
      :upload,
      fields_attributes: [:id, :editable, :multiline, :color, :default_value]
    )
  end

  # Whitelist post parameters for create
  def template_params
    params.required(:slide_template).permit(:name, :upload)
  end
end
