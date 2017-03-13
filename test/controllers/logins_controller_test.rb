require "test_helper"

class LoginsControllerTest < ActionController::TestCase
  def setup
    @login_data = {
      username: "admin",
      password: "test1"
    }
  end

  test "login" do
    post :create, @login_data
    assert_redirected_to slides_path
    assert_equal users(:admin).id, session[:user_id]
  end

  test "login with json" do
    data = @login_data
    data[:format] = :json
    post :create, data

    assert_response :success
    json = JSON.parse @response.body
    assert_equal "Login successful", json["message"]
    assert_equal users(:admin).username, json["data"]["username"]
    assert_equal users(:admin).id, session[:user_id]
  end

  test "failed login" do
    data = @login_data
    data[:password] = "wrong password"

    post :create, data

    assert_template :show
    assert_not session[:user_id].present?
  end

  test "failed login with json" do
    data = @login_data
    data[:password] = "wrong password"
    data[:format] = :json

    post :create, data

    assert_response 403, "Response code wasn't 403 Forbidden"
    json = JSON.parse @response.body
    assert_equal json["message"], "Login invalid"
  end

  test "return to url in session" do
    data = @login_data
    post :create, data, login_return_to: slide_path(1)

    assert_redirected_to slide_path(1)
  end

  test "return to rul blacklist" do
    data = @login_data
    post :create, data, login_return_to: login_path
    assert_redirected_to slides_path
  end
end
