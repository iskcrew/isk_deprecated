require 'test_helper'

class LoginsControllerTest < ActionController::TestCase
  def setup
  	@login_data = {
  		username: 'admin',
			password: 'test1'
  	}
  end
	
	test "login" do
  	post :create, @login_data
		assert_redirected_to slides_path
  end
	
	test "login with json" do
		data = @login_data
		data[:format] = :json
		
		post :create, data
		
		assert_response :success
		json = JSON.parse @response.body
		assert_equal 'Login successful', json['message']
		assert_equal users(:admin).username, json['data']['username']
	end
	
	test "failed login" do
		data = @login_data
		data[:password] = 'wrong password'
		
		post :create, data
		
		assert_template :show
		assert_not flash[:error].empty?
	end
	
end
