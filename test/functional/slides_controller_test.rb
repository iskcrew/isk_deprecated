require 'test_helper'

class SlidesControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
	
	def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
		@new_slide_data = {
			slide: {
				name: "New test slide",
				public: "false",
				show_clock: "false"
			},
			create_type: 'simple'
		}
	end
	
	test "get index" do
		get :index, nil, @adminsession
		
		assert_response :success
		
	end
	
	test "get slide details" do
		get :show, {id: slides(:no_clock)}, @adminsession
		
		assert_response :success
	end
	
	test "get new slide form" do
		get :new, nil, @adminsession
		
		assert_response :success
	end
	
	test "get edit form" do
		get :edit, {id: slides(:no_clock)}, @adminsession
		
		assert_response :success
	end
	
	test "update slide" do
		put :update, {id: slides(:no_clock), slide: {show_clock: true}}, @adminsession
		
		assert_redirected_to slide_path(assigns(:slide))
	end
	
	test "create new slide" do
		assert_difference('Slide.count', 1) do
			post :create, @new_slide_data, @adminsession
		end
		assert_redirected_to slide_path(assigns(:slide))
	end
	
end
