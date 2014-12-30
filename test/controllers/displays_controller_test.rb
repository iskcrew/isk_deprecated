require 'test_helper'

class DisplaysControllerTest < ActionController::TestCase
	#TODO: test sorting overrides
	
  def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
		@update_data = {
			display: {
				name: "paranormal"
			},
			id: displays(:normal).id
		}
		
		@add_queue_data = {
			id: displays(:normal).id,
			slide_id: slides(:slide_1).id
		}
		
		@remove_queue_data = {
			id: 2
		}
		
		@all_displays = [:normal, :no_presentation, :late, :with_overrides, :manual_mode, :no_timestamps]
  end
	
	
	test "get index" do
		get :index, nil, @adminsession
		
		assert_response :success
	end
	
	test "get index as json" do
		get :index, {format: :json}, @adminsession
		assert_response :success
		body = JSON.parse response.body
		assert_equal Display.count, body.size, "JSON response array didn't have correct amount of elements"
	end
	
	test "get display info" do
		@all_displays.each do |d|
			get :show, {:id => displays(d)}, @adminsession
			assert_response :success, "Error getting info for display: " + d.to_s
		end
	end
	
	test "get edit form" do
		@all_displays.each do |d|
			get :edit, {:id => displays(d)}, @adminsession
			assert_response :success, "Error getting edit for display: " + d.to_s
		end
	end
	
	test "update display" do
		patch :update, @update_data, @adminsession
		
		assert_redirected_to display_path(assigns(:display))
	end
	
	test "get dpy control" do
		get :dpy_control, {id: displays(:normal).id}, @adminsession
		
		assert_response :success
	end
		
	test "remove override" do
		assert_difference "displays(:with_overrides).override_queues.count", -1 do
			post :remove_override, @remove_queue_data, @adminsession
		end
		
		assert_response :redirect
	end
	
	test "change presentation" do
		assert_not displays(:normal).presentation_id == presentations(:with_hidden_slides), "Fixture has the presentation already"
		data = {
			id: displays(:normal), 
			display: {presentation_id: presentations(:with_hidden_slides).id}
		}
		patch :update, data, @adminsession
		assert_redirected_to display_path(assigns(:display)), "Didn't redirect to show page"
		assert assigns(:display).presentation_id == presentations(:with_hidden_slides).id, "Display presentation didn't change"
	end
	
	
	test "destroy displays" do
		Display.all.each do |d|
			assert_difference "Display.count", -1, "Display wasn't deleted" do
				delete :destroy, {id: d.id}, @adminsession
				assert_redirected_to displays_path
			end
		end
	end
end
