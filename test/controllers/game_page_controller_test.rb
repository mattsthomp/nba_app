require 'test_helper'

class GamePageControllerTest < ActionController::TestCase
  test "should get game" do
    get :game
    assert_response :success
  end

end
