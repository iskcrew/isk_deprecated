require 'test_helper'
require 'test_tubesock'

class TubesockControllerTest < ActionController::TestCase
	include TestTubesock::TestHelpers
	
	def setup
		@adminsession = {user_id: users(:admin).id, username: users(:admin).username}
	end
	
	def teardown
	end
	
	test "invalid message" do
		tube :general, nil, @adminsession, ['asd'].to_json
		assert tubesock_output.empty?
	end
	
	test "simple svg generation" do
		msg = IskMessage.new('simple','svg', {
			heading: 'Websocket test',
			text: 'Houston, we have <connection>!'
		})
		
		tube :general, nil, @adminsession, msg.encode
		
		assert_not tubesock_output.empty?
		msg = IskMessage.from_json tubesock_output.first
		assert msg.object == 'simple'
		assert msg.payload.include? 'Websocket test'
		assert msg.payload.include? 'Houston, we have'
		assert_not msg.payload.include? '<connection>'
	end
end
