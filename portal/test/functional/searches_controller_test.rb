require 'test_helper'

class SearchesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

  test "should get results" do
    get :results
    assert_response :success
  end

  test "should get controlaccess" do
    get :controlaccess
    assert_response :success
  end

end
