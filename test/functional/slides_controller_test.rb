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
				show_clock: "false",
				svg_data: File.read(Rails.root.join('data', 'templates', 'simple.svg'))
			},
			create_type: 'simple'
		}
		
		Slide.send(:remove_const, :FilePath)
		Slide.const_set(:FilePath, Rails.root.join('tmp','test'))
	end
	
	test "get index" do
		get :index, nil, @adminsession
		
		assert_response :success
		
	end
	
	test "get slide details" do
		[:no_clock, :slide_1, :not_ready, :hidden].each do |s|
			get :show, {id: slides(s)}, @adminsession
		
			assert_response :success, "Error getting show for slide: " + s.to_s
		end
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
	
	#FIXME: need to clear the files created
	test "create new simple_slide" do
		assert_difference('Slide.count', 1) do
			post :create, @new_slide_data, @adminsession
		end
		
		assert_redirected_to slide_path(assigns(:slide))
	end
	
	test "add slide to group" do
		assert_difference "MasterGroup.find(master_groups(:one_slide).id).slides.count" do
			post :add_to_group, {id: slides(:ungrouped), add_to_group: {group_id: master_groups(:one_slide)}}, @adminsession
		end
		
		assert_redirected_to root_path
		
	end
	
end
