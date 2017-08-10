require "test_helper"

class TokensControllerTest < ActionController::TestCase
  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
  end

  test "Create a token" do
    assert_difference("User.find(1).auth_tokens.count") do
      post :create, { user_id: 1 }, @adminsession
    end
    assert_redirected_to users_path
  end

  test "Delete a token" do
    assert_difference("User.find(1).auth_tokens.count", -1) do
      delete :destroy, { user_id: 1, id: 1 }, @adminsession
    end
    assert_redirected_to users_path
  end
end
