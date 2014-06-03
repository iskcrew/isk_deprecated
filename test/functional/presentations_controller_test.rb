require 'test_helper'

class PresentationsControllerTest < ActionController::TestCase
	#TODO: Test sorting the groups and adding and removing groups
	
	
	def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
		@new_presentation_data = {
			presentation: {
				name: "New test presentation",
				delay: 20
			}
		}
		@update_data = {
			id: presentations(:with_slides).id,
			presentation: {
				name: "I have been updated"
			}
		}
	end
	
	test "get index" do
		get :index, nil, @adminsession
		
		assert_response :success
	end
	
	test "get info on presentation" do
		get	:show, {id: presentations(:with_slides).id}, @adminsession
		
		assert_response :success
	end
	
	test "get new presentation form" do
		get :new, nil, @adminsession
		
		assert_response :success
	end
	
	test "create new presentation" do
		assert_difference "Presentation.count", 1 do
			post :create, @new_presentation_data, @adminsession
		end
		
		assert_redirected_to presentation_path(assigns(:presentation))
	end
	
	test "get update form" do
		get :edit,{id: presentations(:with_slides).id }, @adminsession
		
		assert_response :success
	end
	
	test "update presentation" do
		put :update, @update_data, @adminsession
		
		assert_redirected_to presentation_path(assigns(:presentation))
		assert_equal "I have been updated", assigns(:presentation).name
	end
	
	test "get presentation preview" do
		[
			:with_slides,
			:empty,
			:with_empty_group,
			:with_hidden_slides,
			:with_special_duration
		].each do |p|
			get :preview, {id: presentations(p).id}, @adminsession
			
			assert_response :success, "Failed to get preview for presentation: " + p.to_s
		end
	end	
	
	test "add a group to presentation" do
		add_group_data = {
			id: presentations(:with_slides).id,
			group: {
				id: master_groups(:one_slide).id
			}
		}
		assert_difference "presentations(:with_slides).groups.count" do
			post :add_group, add_group_data, @adminsession
		end
		
		assert_redirected_to root_path
	end
	
	test "sort presentation" do
		p = presentations(:with_slides)
		data = {id: p.id, group: ['2', '3', '4', '1'], format: 'js'}
		post :sort, data, @adminsession
		
		p = assigns(:presentation)
		p.reload
		
		assert_equal 2, p.groups.first!.id, "First group should be id 1"
		assert_equal 1, p.groups.last!.id , "Last group should be id 1"
		
	end
	
end
