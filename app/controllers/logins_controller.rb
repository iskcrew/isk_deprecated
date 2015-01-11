# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md


class LoginsController < ApplicationController
	skip_before_action :require_login, :only => [:show, :create]

	layout :login_layout

	def show
		@user = current_user
	end

	def create
		if user = User.authenticate(params[:username],params[:password])
			reset_session # Protect from session fixation attacks
			session[:user_id] = user.id
			session[:username] = user.username
			flash[:notice] = "Login successful"
		else
			flash[:error] = "Login invalid"
			respond_to do |format|
				format.html {render :show}
				format.json {
					json = {message: flash[:error]}
					render json: json.to_json, status: :forbidden
				}
			end
			return
		end
		respond_to do |format|
			format.html { redirect_to slides_path }
			format.json {
				json = { message: flash[:notice], data: {username: user.username} }
				render json: json.to_json
			}
		end
	end

	def destroy
		reset_session
		flash[:notice]="User logged out"
		redirect_to :action => :show
	end

	private

	def login_layout
		current_user ? 'application' : 'not_logged_in'
	end

end
