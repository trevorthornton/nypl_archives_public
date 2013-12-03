require 'test_helper'

class CollectionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get view" do
    get :view
    assert_response :success
  end

  test "should get container_list" do
    get :container_list
    assert_response :success
  end

end
