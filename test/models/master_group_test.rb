require "test_helper"
require "redis_test_helpers"

class MasterGroupTest < ActiveSupport::TestCase
  include RedisTestHelpers

  test "Create new prize group" do
    skip("Needs a template in test assets to work")

    awards = [{ name: "Fooo", by: "Me", pts: "3" }, { name: "Bar", by: "You", pts: "2" }]
    data = {
      title: "Test awards",
      awards: awards
    }
    pg = PrizeGroup.new(
      name: "Competition Competition",
      data: data
    )

    assert pg.save!

    pg = PrizeGroup.find(pg.id)

    assert pg.slides.count == 3, "Prizegroup didn't have correct number of slides"
    assert pg.name == "Competition Competition"
    assert pg.data[:awards][0][:name] == "Fooo"
    assert pg.data[:awards][1][:by] == "You"

    pg.slides.each do |s|
      clear_slide_files(s)
    end
  end

  test "destroy a group" do
    assert_difference "MasterGroup.count", -1 do
      assert_difference "MasterGroup.find(10).slides.count", master_groups(:ten_slides).slides.count do
        master_groups(:ten_slides).destroy
      end
    end
  end

  test "notifications on create" do
    g = MasterGroup.new(name: "test groups")
    with_redis do
      assert g.save
    end
    assert_one_isk_message("mastergroup", "create")
  end

  test "notification on update" do
    g = master_groups(:ten_slides)
    with_redis do
      g.name = "updated name"
      assert g.save
    end
    assert_one_isk_message("mastergroup", "update")
  end

  test "notifications on delete" do
    mg = master_groups(:ten_slides)
    slides_count = mg.slides.count
    with_redis do
      mg.destroy
    end
    assert_equal slides_count, redis_messages.count, "Should trigger #{slides_count} notifications about slides"
    redis_messages.each do |m|
      assert msg = IskMessage.from_json(m)
      assert_equal "slide", msg.object
      assert_equal "update", msg.type
    end
  end
end
