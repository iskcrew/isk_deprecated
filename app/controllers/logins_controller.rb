# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class LoginsController < ApplicationController
	
	# ACLs, we skip the requirement of having a logged in user for the login process
	skip_before_action :require_login, :only => [:show, :create]

	# Choose the layout depending if user has logged in
	# The layout for no logged in user is simplified and includes the minimal amount of javascript
	layout :login_layout

	# Show the login page
	def show
	end

	# Log a user in
	# Supports both html and json requests
	def create
		if user = User.authenticate(params[:username],params[:password])
			# Login successful
			reset_session # Protect from session fixation attacks
			session[:user_id] = user.id
			session[:username] = user.username
			flash[:notice] = "Login successful"
			# Either redirect to slide index or render the json response
			respond_to do |format|
				format.html { redirect_to slides_path }
				format.json {
					json = { message: flash[:notice], data: {username: user.username} }
					render json: json.to_json
				}
			end
      return
    elsif display = Token.authenticate_display(params[:token])
      reset_session
      session[:display_id] = display.id
      render json: { message: "Authenticated display: #{display.name}", display_id: display.id}
      return
		else
			# Username or password was invalid
			flash[:error] = "Login invalid"
			# Either render the login page or a json response with 403 forbidden status
			respond_to do |format|
				format.html {render :show}
				format.json {
					json = {message: flash[:error]}
					render json: json.to_json, status: :forbidden
				}
			end
		end
	end

	# Logout
	def destroy
		reset_session
		flash[:notice]="User logged out"
		respond_to do |format|
			format.html { redirect_to login_path, status: :see_other }
			format.json { 
				render json: { message: flash[:notice] }
				flash.clear
			}
		end
	end

	private

	# Choose what layout to use
	def login_layout
		current_user ? 'application' : 'not_logged_in'
	end
end
