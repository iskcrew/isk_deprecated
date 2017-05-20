require "test_helper"
require "test_tubesock"

class TubesockControllerTest < ActionController::TestCase
  include TestTubesock::TestHelpers

  def setup
    @adminsession = { user_id: users(:admin).id, username: users(:admin).username }
  end

  def teardown; end

  test "invalid message" do
    tube :general, nil, @adminsession, ["asd"].to_json
    assert tubesock_output.empty?
  end

  test "simple svg generation" do
    msg = IskMessage.new("command", "simple_svg",
                         heading: "Websocket test",
                         text: "Houston, we have <connection>!")

    tube :general, nil, @adminsession, msg.encode

    msg = assert_one_sent_message("simple", "svg")
    assert msg.payload.include? "Websocket test"
    assert msg.payload.include? "Houston, we have"
    assert_not msg.payload.include? "<connection>"
  end

  test "slide template svg generation" do
    skip "Needs SlideTemplate fixtures"

    msg = IskMessage.new("simple", "svg",
                         template_id: 1,
                         field1: "Test string")

    tube :general, nil, @adminsession, msg.encode

    msg = assert_one_sent_message("command", "template_svg")
    assert msg.object == "template"
    assert msg.payload.include? "Test string"
  end
end
