require 'test_helper'

class UsersControllerTest < ActionController::TestCase
	def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
		@create_data = {
			user: {username: 'new_user'},
			password: {
				password: 'asd',
				verify: 'asd'
			}
		}
	end
	
	test "get index" do
		get :index, nil, @adminsession
		assert_response :success
	end
	
	test "get user details" do
		User.all.each do |u|
			get :show, {id: u.id}, @adminsession
			assert_response :success, "Failed to get user details for user #{u.username}"
		end
	end
	
	test "create new user" do
		get :new, nil, @adminsession
		assert_response :success, 'Error getting new user form'
		
		assert_difference 'User.count' do
			post :create, @create_data, @adminsession
			assert_redirected_to users_path
		end
	end
	
	test "verify roles on grant form" do
		User.all.each do |user|
			get :roles, {id: user.id}, @adminsession
			assert_response :success, "Failed to get permission form for user #{user.username}"
			
			assert_select 'form input[type="checkbox"]', {count: Role.count}
			assert_select 'form input[type="checkbox"][checked="checked"]', {count: user.roles.count}
		end
	end

end
