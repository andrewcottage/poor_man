ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    # 
    def login(user = nil)
      user ||= users(:one)
      post sessions_url, params: {session: { email: user.email, password: 'password' } }

      assert_response :redirect
    end
  end
end
