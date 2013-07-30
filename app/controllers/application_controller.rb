
class ApplicationController < ActionController::Base
  #protect_from_forgery
  helper_method :home_domain

  before_filter :require_login


  class PermissionDenied < StandardError
    # no further implementation necessary
  end

  class ConvertError < StandardError
    # no further implementation necessary
  end


  #Minne websocketti ottaa yhteyttä?
  def home_domain
    Rails.env.production? ? 'isk0.asm.fi' : root_url.to_s.split("//")[1]
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
    User.includes(:roles).find_by_id(session[:user_id])
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
      format.any  { head status } # only return the status code
    end
  end


end
