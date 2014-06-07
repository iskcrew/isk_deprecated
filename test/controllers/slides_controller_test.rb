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
		
		@forbidden_actions = {
			get: [
				[:index, nil],
				[:show, id: 1],
				[:new, nil],
				[:edit, id: 1],
				[:svg_data, id: slides(:inkscape).id]
			],
			post: [
				[:svg_save, id: slides(:inkscape)],
				[:ungroup, id: 1],
				[:undelete, id: slides(:deleted).id],
				[:hide, id: 1],
				[:deny, id: 1],
				[:grant, id: 1],
				[:to_inkscape, id: slides(:simple)],
				[:to_simple, id: slides(:svg)],
				[:add_to_group, id: slides(:ungrouped)],
				[:add_to_override, {id: 1, add_to_override: {display_id: 1}}],
				[:clone, id: 1],
				[:create, slide: {name: 'foo'}]
			],
			put: [[:update, id: 1]],
			patch: [[:update, id: 1]],
			delete: [[:destroy, id: 1]]
		}
		
		Slide.send(:remove_const, :FilePath)
		Slide.const_set(:FilePath, Rails.root.join('tmp','test'))
		
	end
	
	def teardown
		#Remove any possible files associated with test data from
		#the test directory
		
		Slide.all.each do |s|
			clear_slide_files(s)
		end
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
	
	test "update simple slide" do
		put :update, {id: slides(:simple), slide: {slidedata: {heading: 'fooo'}}}, @adminsession
		
		assert_redirected_to slide_path(assigns(:slide))
		s = Slide.find(slides(:simple).id)
		assert_equal 'fooo', assigns(:slide).slidedata[:heading], "Slide heading didn't update"
		
		#FIXME: why this fails?
		#assert s.ready, "Slide should have had it's picture generated"
		
		assert File.exists?(s.svg_filename), "The slide svg file wasn't generated"
		assert File.exists?(s.full_filename), "The full slide image wasn't generated"
		assert s.svg_data.include?('>fooo<'), "SVG didn't contain the new header"
		
		put :update, {id: slides(:simple), slide: {public: false}}, @adminsession
		assert_redirected_to slide_path(assigns(:slide))
		assert !assigns(:slide).public, "Slide didn't become hidden" 

		
	end
	
	test "create new simple_slide" do
		assert_difference('Slide.count', 1) do
			post :create, @new_slide_data, @adminsession
		end
		
		assert_redirected_to slide_path(assigns(:slide))
		s = assigns(:slide)
		assert File.exists?(s.svg_filename), "The slide svg file wasn't generated"
		assert File.exists?(s.full_filename), "The full slide image wasn't generated"
		
		# Clear the files
		clear_slide_files(s)
	end
	
	test "add slide to group" do
		assert_difference "MasterGroup.find(master_groups(:one_slide).id).slides.count" do
			post :add_to_group, {id: slides(:ungrouped), add_to_group: {group_id: master_groups(:one_slide)}}, @adminsession
		end
		
		assert_redirected_to root_path
		
	end
	
	test "ungroup a slide" do
		assert_difference("Event.current.ungrouped.slides.count") do
			post :ungroup, {id: slides(:no_clock)}, @adminsession
		end
		
		assert_redirected_to root_path
	end
	
	test "add a slide to override" do
		assert_difference("Display.find(displays(:normal).id).override_queues.count") do
			post :add_to_override, {id: slides(:no_clock),  
				add_to_override: {display_id: displays(:normal).id, effect_id: effects(:fancy)}}, 
				@adminsession
		end
		
		assert_redirected_to root_path
	end
	
	# Try to get all actions of this controller without a user
	test "acl without user" do
		assert_actions_denied(@forbidden_actions)
	end
	
	test "acl without roles" do
		# All get actions should be ok even without any roles
		actions = @forbidden_actions
		actions.delete(:get)
		session = {user_id: users(:no_roles).id, username: users(:no_roles).username}
		assert_actions_denied(actions, session, false)
	end
	
end
