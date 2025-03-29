require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:andrew)
  end

  test "should get new" do
    get new_session_url
    assert_response :success
  end

  test "should login user with valid credentials" do
    post sessions_url, params: { 
      session: { 
        email: @user.email, 
        password: 'password' 
      } 
    }
    assert_equal @user.id, session[:user_id]
    assert_redirected_to root_url
  end

  test "should not login user with invalid credentials" do
    post sessions_url, params: { 
      session: { 
        email: @user.email, 
        password: 'wrong_password' 
      } 
    }
    assert_nil session[:user_id]
    assert_response :success # renders new template
  end

  test "should logout user" do
    login
    delete session_url(@user.id)
    assert_nil session[:user_id]
    assert_redirected_to root_url
  end
end 