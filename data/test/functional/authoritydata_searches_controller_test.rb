require 'test_helper'

class AuthoritydataSearchesControllerTest < ActionController::TestCase
  test "should get show" do
    get :show
    assert_response :success
  end

  test "should get results" do
    get :results
    assert_response :success
  end

end
