require 'test_helper'

class CollectionAssociationsControllerTest < ActionController::TestCase
  test "should get create" do
    get :create
    assert_response :success
  end

  test "should get delete" do
    get :delete
    assert_response :success
  end

  test "should get destroy" do
    get :destroy
    assert_response :success
  end

end
