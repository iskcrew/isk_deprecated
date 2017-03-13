require "test_helper"

class PermissionsControllerTest < ActionController::TestCase
  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
  end

  test "add authorized user to slide" do
    slide = slides(:simple)
    user = users(:no_roles)
    assert slide.authorized_users.empty?, "Slide had authorized users before test!"
    post :create, { slide_id: slide.id, grant: { user_id: user.id } }, @adminsession
    assert_response :found
    assert slide.reload
    assert slide.authorized_users.include? user
  end

  test "remove authorized user from display" do
    display = displays(:with_display_counts)
    user = users(:limited)
    assert display.authorized_users.include? user
    delete :destroy, { display_id: display.id, user_id: user.id }, @adminsession
    assert_response :found
    assert display.reload
    assert_not display.authorized_users.include? user
  end
end
