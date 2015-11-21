require 'test_helper'
require 'redis_test_helpers'

class GroupTest < ActiveSupport::TestCase
	include RedisTestHelpers
	
	test "notifications on create" do
		p = presentations(:with_slides)
		mg = master_groups(:one_slide)
		g = Group.new
		g.presentation = p
		g.master_group = mg
		with_redis do
			assert g.save
		end
		assert_one_isk_message('group', 'create')
	end
	
	test "notifications on update" do
		g = groups(:group_2)
		mg = master_groups(:one_slide)
		with_redis do
			g.master_group = mg
			assert g.save
		end
		assert_one_isk_message('group', 'update')
	end
	
	test "notifications to displays" do
		g = groups(:group_2)
		d = g.displays.sample
		with_redis(d.websocket_channel) do
			g.position_position = :last
			assert g.save
		end
		assert_one_isk_message('display', 'data')
	end
end
