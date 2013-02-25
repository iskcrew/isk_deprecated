class ApplicationController < ActionController::Base
  #protect_from_forgery
  
  before_filter :require_login
  
  
  class PermissionDenied < StandardError
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
        User.includes(:roles).find_by_id(session[:user_id])
  end
  
  private
  
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
  
  
  def authorize
    if request.authorization
      username, password = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
      return username
    else
      return 'isk'
    end
  end
  
  def authorize_isk
    if authorize == 'isk'
      return true
    else
      flash[:error] = 'You are not allowed to do this!'
      redirect_to :back
    end
  end
  
  def authorize_seminar
    if authorize == 'isk' || authorize == 'seminar'
      return true
    else
      flash[:error] = 'You are not allowed to do this!'
      redirect_to :back
    end
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
