# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class SlidesController < ApplicationController
  # ACLs
  before_action :require_create, only: [:new, :create, :clone]
  before_action :require_admin, only: [:deny, :grant, :to_inkscape, :to_simple]
  # Do not require login for getting the slide pictures
  skip_before_action :require_login, only: [:preview, :full, :thumb]

  # List all slides in the current event
  # TODO: Better support for filtering the slide list...
  def index
    if params[:filter] == "thrashed"
      @groups = [current_event.thrashed]
      @filter = :thrashed
    else
      @groups = []
      @groups << current_event.ungrouped
      @groups += MasterGroup.current.order("LOWER(master_groups.name)").all
    end

    respond_to do |format|
      format.js
      format.html
    end
  end

  # Show details for a single slide, we also support ajax calls to replace
  # the slide info block as needed
  def show
    @slide = Slide.find(params[:id])

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Render a form for creating a new slide
  # Reduced user permissions might limit what we allow the user to create
  def new
    @slide = Slide.new

    respond_to do |format|
      format.html
      format.js do
        @slide = TemplateSlide.new(foreign_object_id: params[:slide_template_id])
      end
    end
  end

  # Create a new slide
  # We support creating all the different types of slides.
  # TODO: create inkscape-slides based on svg templates
  # FIXME: TemplateSlide fields dont maintain their values!
  def create
    # We need to use a transaction to catch potential errors on processing
    # submitted image data
    Slide.transaction do
      # Create the requested type of slide
      case params[:create_type]
      when "simple"
        @slide = SimpleSlide.new(slide_params)
      when "http_slide"
        @slide = HttpSlide.new(slide_params)
      when "empty_file", "inkscape"
        @slide = InkscapeSlide.new(slide_params)
      when "template"
        @slide = TemplateSlide.new(slide_params)
      when "image"
        @slide = ImageSlide.new(slide_params)
      else
        @slide = Slide.new(slide_params)
      end

      unless @slide.save
        respond_to do |format|
          format.html do
            flash[:error] = "Error saving slide."
            render :new_after_error
          end
          format.json do
            render json: {
                           message: "Error saving slide.",
                           errors: @slide.errors.messages
                         },
                   status: :bad_request
          end
        end
        return
      end

      @slide.reload

      # FIXME: The file operations could be prettier and in models
      # They need to be done after we know the slide id....
      case params[:create_type]
      when "empty_file", "inkscape"
        # FIXME: Intialize the svg in the model!
        @slide.svg_data = SimpleSlide.create_svg(SimpleSlide::DefaultSlidedata)
      end

      unless @slide.can_edit? current_user
        @slide.authorized_users << current_user
      end
    end # Transaction

    if @slide.is_a? HttpSlide
      @slide.fetch_later
    else
      @slide.generate_images_later
    end

    respond_to do |format|
      format.html { redirect_to slide_path(@slide) }
      format.json do
        render json: {
                       message: "Slide was successfully created.",
                       slide_id: @slide.id
                     },
               status: :created
      end
    end
  rescue Slide::ImageError
    # image invalid
    flash[:error] = "Error creating slide, invalid image file."
    render action: :new_after_error
  end

  # Edit a slide
  def edit
    @slide = Slide.find(params[:id])
    require_edit(@slide)
  end

  # Update a slide
  def update
    Slide.transaction do
      @slide = Slide.find(params[:id])
      require_edit(@slide)

      if @slide.update_attributes(slide_params)
        # Generate images as needed
        # FIXME: This needs to be more universal..
        @slide.generate_images_later if !@slide.is_a?(HttpSlide) && !@slide.ready
        # Fetch the http slide image if needed
        @slide.fetch_later if @slide.is_a?(HttpSlide) && @slide.needs_fetch?

        respond_to do |format|
          format.html do
            flash[:notice] = "Slide was successfully updated."
            redirect_to slide_path(@slide)
            return
          end
          format.js { render :show }
          format.json do
            render json: {
                           id: @slide.id,
                           message: "Slide was succesfully updated.",
                           changes: @slide.previous_changes
                         }
          end
        end
      else
        flash[:error] = "Error updating slide"
        render action: :edit
        return
      end
    end
  end

  # Mark a slide as deleted, we don't hard-delete slides ever
  def destroy
    @slide = Slide.find(params[:id])
    require_edit @slide
    @slide.destroy
    @slide.save!
    respond_to do |format|
      format.html { redirect_to slide_path(@slide) }
      format.js { render :show }
    end
  end

  # Remove the deleted flag and move the slide from thrash to ungrouped.
  def undelete
    @slide = Slide.find(params[:id])
    require_edit(@slide)
    @slide.undelete
    @slide.save!
    redirect_to slide_path(@slide)
  end

  # Create a clone of the slide
  def clone
    old_slide = Slide.find(params[:id])
    slide = old_slide.clone!
    slide.generate_images_later unless slide.ready
    flash[:notice] = "Slide cloned."
    redirect_to slide_path(slide)
  end

  # TODO: move ungroup -action into slide model
  def ungroup
    slide = Slide.find(params[:id])
    require_edit(slide)
    slide.master_group = current_event.ungrouped
    slide.save!
    flash[:notice] = "Ungrouped slide: #{slide.name}"
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :index }
    end
  end

  # Add a slide from the current events ungrouped slides group to a real
  # group.
  # FIXME: merge this logic to update method and kill this off.
  def add_to_group
    begin
      slide = current_event.ungrouped.slides.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      # No slide was found in the current events ungrouped slides group
      flash[:error] = "This slide is already in a group."
      redirect_to :back
      return
    end

    require_edit(slide)

    group = current_event.master_groups.find(params[:add_to_group][:group_id])
    require_edit(group)

    group.slides << slide
    flash[:notice] = "Added slide #{slide.name} to group #{group.name}."
    redirect_to :back
  end

  # Add slide to override queue on a display
  def add_to_override
    slide = Slide.current.find(params[:id])
    display = Display.find(params[:add_to_override][:display_id])

    unless display.can_override? current_user
      raise ApplicationController::PermissionDenied
    end

    effect = Effect.find params[:add_to_override][:effect_id]
    display.add_to_override(slide,
                            params[:add_to_override][:duration].to_i,
                            effect)

    unless display.do_overrides
      flash[:warning] = "WARNING: This display isn't currently showing"\
                        " overrides, displaying this slide will be delayed"
    end
    flash[:notice] = "Added slide #{slide.name} to override queue for"\
                     " display #{display.name} with effect #{effect.name}"

    redirect_to :back
  end

  # FIXME: Merge to update and check permissions as needed there
  # We can even use params whitelisting to make this extra-easy!
  def hide
    @slide = Slide.find(params[:id])
    unless @slide.can_hide? current_user
      raise ApplicationController::PermissionDenied
    end
    @slide.public = false
    @slide.save!

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render :show }
    end
  end

  # Get the svg datafile for a slide for external editing in inkscape etc.
  # FIXME: move svg handling to nexted svg controller
  def svg_data
    @slide = Slide.find(params[:id])
    @slide.update_metadata! if @slide.is_a? InkscapeSlide
    send_file(@slide.svg_filename, disposition: "attachment",
                                   type: "image/svg+xml")
  end

  # Save the submitted svg to a slide. Used by the inkscape plugins
  # FIXME: basic validation for the incoming svg
  def svg_save
    @slide = InkscapeSlide.find(params[:id])
    require_edit(@slide)

    @slide.svg_data = params[:svg]
    @slide.save!
    @slide.generate_images_later
    render body: nil
  end

  # Convert a slide to InkscapeSlide
  # TODO: This needs a major cleanup
  def to_inkscape
    slide = SimpleSlide.find(params[:id])
    ink = InkscapeSlide.create_from_simple(slide)
    slide.replace! ink
    flash[:notice] = "Slide was converted to inkscape slide."
    redirect_to slide_path(ink)
  end

  # Convert a slide to a simple editor slide
  def to_simple
    slide = SvgSlide.find(params[:id])
    begin
      Slide.transaction do
        simple = SimpleSlide.create_from_svg_slide(slide)
        slide.replace! simple
        flash[:notice] = "Slide was converted simple slide."
        redirect_to slide_path(simple)
      end
    rescue Slide::ConvertError
      flash[:error] = "Conversion error, maybe slide has images?"
      redirect_to slide_path(slide)
    end
  end

  # Send the slide preview image, we set the cache headers
  # to avoid unecessary reloading
  def preview
    redirect_to slide_image_path(params[:id], size: :preview)
  end

  def thumb
    redirect_to slide_image_path(params[:id], size: :thumb)
  end

  # Send the full sized slide image
  # We will always send the last rendered image if it exists
  # If not we will issue 404 status
  def full
    redirect_to slide_image_path(params[:id])
  end

private

  # Whitelist the accepted slide parameters for update and create
  def slide_params
    params.required(:slide).permit(
      :name, :description, :show_clock, :public, :duration, :foreign_object_id,
      :master_group_id, :image,
      slidedata: params[:slide][:slidedata].try(:keys)
    )
  end

  def require_create
    return if Slide.can_create? current_user
    raise ApplicationController::PermissionDenied
  end

  def require_admin
    return if Slide.admin? current_user
    raise ApplicationController::PermissionDenied
  end
end
