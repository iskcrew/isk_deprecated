# frozen_string_literal: true
require "test_helper"

class HistoryControllerTest < ActionController::TestCase
  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
  end

  test "get empty history" do
    d = displays(:normal)
    get :index, { display_id: d.id }, @adminsession
    assert_response :success
  end

  test "get history with few entries" do
    d = displays(:with_display_counts)
    get :index, { display_id: d.id }, @adminsession
    assert_response :success
  end

  test "clear history" do
    d = displays(:with_display_counts)
    assert_difference "DisplayCount.count", -d.display_counts.count do
      post :clear, { display_id: d.id }, @adminsession
      assert_redirected_to display_history_index_path(d)
    end
  end
end
