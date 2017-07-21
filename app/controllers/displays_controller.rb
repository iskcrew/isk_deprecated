# frozen_string_literal: true

# ISK - A web controllable slideshow system
#
# This controller handles the managing of remote isk displays.
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class DisplaysController < ApplicationController
  # Tubesock websockets
  include Tubesock::Hijack

  # ACL filters
  before_action :require_create, only: [:new, :create]
  # We send error messages on ACL violations via the websocket
  skip_before_action :require_login, only: :websocket

  # List all displays
  # We support html or json for the whole list and
  # js for updating the late display warnings on pages.
  def index
    @displays = Display.order(:name)

    respond_to do |format|
      format.js
      format.html
      format.json do
        render json: @displays.collect do |d|
          {
            id: d.id,
            name: d.name,
            status: d.status,
            late: d.late?
          }
        end
      end
    end
  end

  # Get the details on a given display
  # We support html, json for the data serilazation and
  # js for updating the div#display_<id> blocks
  def show
    @display = Display.includes(:presentation, override_queues: :slide)
                      .find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        render json: JSON.pretty_generate(@display.to_hash)
      end
      format.js
    end
  end

  # Delete a display and associated data
  def destroy
    # Only admins can delete displays
    require_admin

    display = Display.find(params[:id])
    display.destroy
    flash[:notice] = "Deleted display id: #{display.id} - #{display.name}"
    redirect_to displays_path, status: :see_other
  end

  def new
    @display = Display.new
  end

  def create
    @display = Display.new(display_params)

    if @display.save
      flash[:notice] = "Display created."
      redirect_to display_path(@display)
    else
      flash.now[:error] = "Error creating display."
      render action: :new
    end
  end

  # Render the edit form for a given display
  def edit
    @display = Display.find(params[:id])
    require_edit @display
  end

  # Update a given display
  # We support html and js, that updates the div#display_<id> block
  def update
    @display = Display.find(params[:id])
    require_edit @display

    if @display.update_attributes(display_params)
      respond_to do |format|
        format.html do
          flash[:notice] = "Display was successfully updated."
          redirect_to display_path(@display), status: :see_other
        end
        format.js { render :show }
      end
    else
      flash.now[:error] = "Error updating display."
      render action: :edit
      return
    end
  end

  # FIXME: create a nested override controller
  def update_override
    oq = OverrideQueue.find(params[:id])
    require_edit oq.display

    oq.duration = params[:override_queue][:duration]
    oq.save!
    flash[:notice] = "Duration was changed"
    redirect_to :back
  end

  def remove_override
    oq = OverrideQueue.find(params[:id]).destroy
    require_override oq.display

    flash[:notice] = "Removed slide from override queue"
    redirect_to :back
  end

  # Remote control for iskdpy via javascript and websockets
  def dpy_control
    @display = Display.find(params[:id])
  end

  # The webgl display
  def dpy
    @display = Display.find(params[:id])
    raise PermissionDenied unless require_display_control(@display)
    render layout: false
  end

  # Local control interface for the running display
  def dpy_local_control
    @display = Display.find(params[:id])
    raise PermissionDenied unless require_display_control(@display)
    render layout: false
  end

  # FIXME: this logic needs to go to the model
  def sort_queue
    @display = Display.find(params[:id])
    require_edit @display
    oq = @display.queue.find(params[:element_id])
    unless oq
      render text: "Invalid request, try refreshing", status: :bad_request
    end

    oq.position_position = params[:element_position]
    oq.save!
    @display.reload
    respond_to do |format|
      format.js { render :sortable_items }
    end
  end

  # Websocket connection for communication with displays
  def websocket
    @display = Display.find(params[:id])

    hijack do |tubesock|
      # Listen on its own thread
      redis_thread = Thread.new do
        # Needs its own redis connection to pub
        # and sub at the same time
        Redis.new(Rails.configuration.x.redis).subscribe @display.websocket_channel do |on|
          on.message do |_channel, message|
            tubesock.send_data message
          end
        end
      end

      tubesock.onopen do
        unless current_user
          tubesock.send_data ["error", "forbidden", {}].to_json
          redis_thread.kill
          tubesock.close
        end
      end

      tubesock.onmessage do |m|
        # Clear the query cache before each action
        # Since this is a persistent thread the cache doesn't
        # get reset automatically.
        ActiveRecord::Base.connection.clear_query_cache
        @display.reload

        Rails.logger.debug "Got websocket message: #{m}"
        # Parse the message
        msg = IskMessage.from_json(m)
        # Instument the action for logging
        instrument_action(msg) do
          # we only care about commands
          break unless msg.object == "command"
          case msg.type
          when "get_data"
            # Request to get the serialization of a display
            # We only reply to the requestor
            msg = IskMessage.new("display", "data", @display.to_hash)
            tubesock.send_data msg.encode
          when "goto_slide"
            # Command that tells the display to change to a specified slide
            raise PermissionDenied unless require_display_control(@display)
            msg.object = "display"
            msg.type = "goto_slide"
            msg.send @display.websocket_channel
          when "start"
            # Display tells that it is starting up
            raise PermissionDenied unless require_display_control(@display)

            @display_connection = true
            @display.status = "running"
            @display.ip = request.remote_ip
            @display.last_hello = Time.now
            @display.save!
            msg = IskMessage.new("display", "start", {})
            msg.send @display.websocket_channel
          when "current_slide"
            # Display informs us that it has changed to a specified slide
            raise PermissionDenied unless require_display_control(@display)
            # Check if the display changed to a slide from override queue
            if msg.payload[:override_queue_id]
              group = -1
              slide = @display.override_queues.find(msg.payload[:override_queue_id]).slide.id
            else
              group = msg.payload[:group_id]
              slide = msg.payload[:slide_id]
            end
            # Validate that the slide was part of the displays slideset
            msg.object = "display"
            if @display.set_current_slide(group, slide)
              msg.type = "current_slide"
              msg.send @display.websocket_channel
            else
              msg.type = "error"
              msg.payload = { error: "Invalid slide specified" }
              tubesock.send_data msg.encode
            end
          when "slide_shown"
            # Display has finished showing a slide
            # We only care about this if the slide was from the override queue
            raise PermissionDenied unless require_display_control(@display)
            if msg.payload[:override_queue_id]
              @display.override_shown(msg.payload[:override_queue_id])
            end
            msg.object = "display"
            msg.type = "slide_shown"
            msg.send @display.websocket_channel
          when "shutdown"
            # Display is performing a controlled shutdown
            raise PermissionDenied unless require_display_control(@display)

            @display_connection = false
            @display.status = "disconnected"
            @display.save!
            msg = IskMessage.new "display", "shutdown", {}
            msg.send @display.websocket_channel
          when "error"
            # Display reports that it has encountered an error
            @display.add_error msg.payload[:error]
            @display.save!
          when "ping"
            # Simple ping-pong so the display can test that the connection is up
            msg.object = "display"
            msg.type = "pong"
            @display.ping
            @display.state.save!
            tubesock.send_data msg.encode
          end
        end
      end

      # Error handlers
      # We just close the socket on all errors and if this connection was
      # from a display we mark its state as invalid.
      tubesock.onerror do |e, data|
        if e.is_a? PermissionDenied
          tubesock.send_data ["error", "forbidden", {}].to_json
        else
          Rails.logger.error "Error handling websocket message #{data}"
        end
        redis_thread.kill
        tubesock.close
        if @display_connection
          @display.status = "error"
          @display.save!
        end
      end

      tubesock.onclose do
        # stop listening when client leaves
        redis_thread.kill
        if @display_connection
          @display.status = "error"
          @display.save!
        end
      end
    end
  end

private

  # Instrument the websocket actions for logging
  def instrument_action(msg)
    options = {
      action: msg.object,
      ip: request.remote_ip,
      message: msg,
      display_connection: @display_connection
    }
    options[:display_name] = @display.name unless @display.nil?
    ActiveSupport::Notifications.instrument("iskdpy", options) do
      yield
    end
  end

  # Require permissions to alter the running state of a display
  def require_display_control(display)
    current_user.has_role?("display-client") || display.can_edit?(current_user)
  end

  # Whitelist the parameters for updating displays
  def display_params
    params.required(:display).permit(:name, :presentation_id,
                                     :manual, :monitor, :do_overrides, :live)
  end

  # Require display admin priviledges or raise PermissionDenied
  def require_admin
    return if Display.admin? current_user
    raise ApplicationController::PermissionDenied
  end

  # Require display create permission or raise PermissionDenied
  def require_create
    return if Display.can_create? current_user
    raise ApplicationController::PermissionDenied
  end

  # Require permission to add slides to the override queue on a display
  def require_override(d)
    return if d.can_override? current_user
    raise ApplicationController::PermissionDenied
  end
end
