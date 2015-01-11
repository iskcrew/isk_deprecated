# ISK - A web controllable slideshow system
#
# Author::		Vesa-Pekka Palmu
# Copyright:: Copyright (c) 2012-2013 Vesa-Pekka Palmu
# License::		Licensed under GPL v3, see LICENSE.md

class ApplicationController < ActionController::Base
	#protect_from_forgery
	before_action :require_login


	class PermissionDenied < StandardError
		# no further implementation necessary
	end

	class ConvertError < StandardError
		# no further implementation necessary
	end

	rescue_from ActionController::RedirectBackError, :with => :return_to_root
	rescue_from ApplicationController::PermissionDenied do |e| 
		http_status_code(:forbidden, e) 
	end

	def return_to_root
		redirect_to :root
	end

	def current_user
		@_current_user ||= session[:user_id] &&
			User.includes(:permissions).find_by_id(session[:user_id])
	end

	def current_event
		@_current_event ||= Event.current
	end

	def append_info_to_payload(payload)
		super
		payload[:user] = current_user
	end

	private
	
	def require_global_admin
		raise ApplicationController::PermissionDenied unless current_user.admin?
	end

	def require_role(r)
		return false unless current_user
		return self.current_user.has_role?(r)
	end

	def require_login
		redirect_to :controller => :logins, :action => :show unless current_user
	end

	def require_edit(obj)
		raise ApplicationController::PermissionDenied unless obj.can_edit? current_user
	end

	def http_status_code(status, exception = nil)
		# store the exception so its message can be used in the view
		@exception = exception

		# Only add the error page to the status code if the reuqest-format was HTML
		respond_to do |format|
			format.html { render :template => "shared/status_#{status.to_s}", :status => status }
			format.any	{ head status } # only return the status code
		end
	end


end
