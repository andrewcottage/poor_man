ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "mocha/minitest"

Dir[Rails.root.join("test/support/**/*.rb")].sort.each { |file| require file }

WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all
    include OpenAITestHelper

    # Add more helper methods to be used by all tests here...
    # 
    def login(user = nil)
      user ||= users(:andrew)
      post sessions_url, params: {session: { email: user.email, password: 'password' } }

      assert_response :redirect
    end
  end
end
