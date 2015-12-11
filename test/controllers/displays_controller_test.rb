require 'test_helper'
require 'redis_test_helpers'
require 'test_tubesock'

class DisplaysControllerTest < ActionController::TestCase
	include RedisTestHelpers
	include TestTubesock::TestHelpers
	
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
	
	test "websocket start" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'start', {})
		with_redis(d.websocket_channel) do 
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_messages(2, ['data', 'start'])
		assert d.reload
		assert_equal 'running', d.status
	end
	
	test "websocket shutdown" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'shutdown', {})
		with_redis(d.websocket_channel) do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_messages(2, ['data', 'shutdown'])
		assert d.reload
		assert_equal 'disconnected', d.status
	end
	
	test "websocket error" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'error', {error: 'Test error'})
		with_redis(d.websocket_channel) do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_messages(2, ['data', 'error'])
		assert d.reload
		assert_equal 'error', d.status
	end
	
	test "websocket slide_shown" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'slide_shown', {group_id: d.presentation.groups.first.id, slide_id: d.presentation.slides.first.id})
		with_redis d.websocket_channel do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_one_isk_message('display', 'slide_shown')
	end
	
	test "websocket override shown" do
		d = displays(:with_overrides)
		msg = IskMessage.new('command', 'slide_shown', {
			override_queue_id: d.override_queues.first.id,
			slide_id: d.override_queues.first.slide.id,
			group_id: -1
			})
		assert_difference "displays(:with_overrides).override_queues.count", -1 do
			with_redis d.websocket_channel do
				tube :websocket, {id: d.id}, @adminsession, msg.encode
			end
		end
		assert_messages 2, ['data', 'slide_shown']
	end
	
	test "websocket current_slide" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'current_slide', {
			slide_id: d.presentation.slides.first.id,
			group_id: d.presentation.groups.first.id
		})
		with_redis d.websocket_channel do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_one_isk_message 'display', 'current_slide'
	end
	
	test "websocket current_slide with override" do
		d = displays(:with_overrides)
		msg = IskMessage.new('command', 'current_slide', {
			slide_id: d.override_queues.first.slide.id,
			override_queue_id: d.override_queues.first.id
		})
		with_redis d.websocket_channel do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_one_isk_message 'display', 'current_slide'
	end
	
	test "websocket goto_slide" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'goto_slide', {
			slide_id: d.presentation.slides.last.id,
			group_id: d.presentation.groups.last.id
			})
		with_redis d.websocket_channel do
			tube :websocket, {id: d.id}, @adminsession, msg.encode
		end
		assert_one_isk_message 'display', 'goto_slide'
	end
	
	test "websocket get_data" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'get_data', {})
		tube :websocket, {id: d.id}, @adminsession, msg.encode
		assert_one_sent_message 'display', 'data'
	end
	
	test "websocket ping" do
		d = displays(:late)
		msg = IskMessage.new('command', 'ping', {asd: 'fooo'})
		tube :websocket, {id: d.id}, @adminsession, msg.encode
		assert_one_sent_message 'display', 'pong'
		d.reload
		assert_in_delta Time.now, d.last_contact_at, 1, "Display last contact didn't update"
	end
	
	test "websocket without session" do
		d = displays(:normal)
		msg = IskMessage.new('command', 'ping', {asd: 'fooo'})
		tube :websocket, {id: d.id}, nil, msg.encode, true
		assert_one_sent_message 'error', 'forbidden'
	end
	
	def assert_messages(count, types)
		assert_equal count, redis_messages.count, "Should have triggered #{count} messages"
		redis_messages.each do |m|
			assert msg = IskMessage.from_json(m), "Should be valid message, data: #{m}"
			assert_equal 'display', msg.object, "Should be about a display"
			assert_includes types, msg.type, "Should have a type in: #{types.join ", "}"
		end
	end
end
