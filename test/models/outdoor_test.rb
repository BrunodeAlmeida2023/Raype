require "test_helper"

class OutdoorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @outdoor = Outdoor.new(user: @user)
  end

  test "should be valid with user" do
    assert @outdoor.valid?
  end

  test "should require user" do
    @outdoor.user = nil
    assert_not @outdoor.valid?
  end

  test "should have correct outdoor_type enum values" do
    assert_equal ["triedo", "led", "digital"], Outdoor.outdoor_types.keys
  end

  test "should have correct outdoor_location enum values" do
    assert_equal ["outdoor_01", "outdoor_02", "outdoor_03"], Outdoor.outdoor_locations.keys
  end

  test "should have correct status enum values" do
    assert_equal ["pending", "outdoor_selected", "date_selected", "art_uploaded", "completed"], Outdoor.statuses.keys
  end

  test "outdoor_type_options should return correct format" do
    options = Outdoor.outdoor_type_options
    assert_equal 3, options.length
    assert_equal ["Outdoor Triedo", "triedo"], options.first
  end

  test "outdoor_location_options should return correct format" do
    options = Outdoor.outdoor_location_options
    assert_equal 3, options.length
  end

  test "outdoor_size_options should return correct format" do
    options = Outdoor.outdoor_size_options
    assert_equal 3, options.length
  end

  test "should have default status as pending" do
    assert @outdoor.status_pending?
  end

  test "recent scope should order by created_at desc" do
    assert_equal :desc, Outdoor.recent.order_values.first.direction
  end
end

