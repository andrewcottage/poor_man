require "test_helper"

class AuthControllerTest < ActionDispatch::IntegrationTest
  test "callback should set session when user is found" do
    # Create a valid user
    user = User.create!(
      email: 'test@example.com', 
      username: 'test', 
      password: 'password', 
      uid: '12345', 
      provider: 'github'
    )
    
    # Mock the from_omniauth class method
    User.expects(:from_omniauth).returns(user)
    
    # Simulate the callback
    get "/auth/github/callback"
    
    # Assertions
    assert_redirected_to root_url
    assert_equal "Logged in!", flash[:notice]
    
    # Check that session was set
    assert_not_nil session[:user_id]
    assert_equal user.id, session[:user_id]
  end
  
  test "callback should not set session when user is invalid" do
    # Create an invalid user
    invalid_user = User.new(email: 'invalid-email', username: '')
    invalid_user.validate # Mark as invalid without saving
    
    # Mock the from_omniauth class method
    User.expects(:from_omniauth).returns(invalid_user)
    
    # Simulate the callback
    get "/auth/github/callback"
    
    # Assertions
    assert_redirected_to root_url
    assert_equal "Failed to login!", flash[:alert]
    assert_nil session[:user_id]
  end
end
