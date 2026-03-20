require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper
  include OpenAITestHelper

  CHROME_BINARY_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium"
  ].freeze

  JS_SYSTEM_TESTS_ENABLED = begin
    chrome_binary = CHROME_BINARY_CANDIDATES.find { |path| File.exist?(path) }
    chrome_binary.present? || system("which google-chrome >/dev/null 2>&1") || system("which chromium >/dev/null 2>&1")
  end

  if JS_SYSTEM_TESTS_ENABLED
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  else
    driven_by :rack_test
  end

  def sign_in_as(user)
    visit new_session_url
    assert_selector "h2", text: "Sign in to your account", wait: 5

    if js_system_tests_enabled?
      page.driver.browser.navigate.to("about:blank")
      sleep 0.2
      visit new_session_url
      assert_selector "h2", text: "Sign in to your account", wait: 5

      page.execute_script(<<~JS, user.email)
        const form = document.querySelector('form');
        const email = form.querySelector('input[name="session[email]"]');
        const password = form.querySelector('input[name="session[password]"]');
        email.value = arguments[0];
        password.value = 'password';
        email.dispatchEvent(new Event('input', { bubbles: true }));
        password.dispatchEvent(new Event('input', { bubbles: true }));
        email.dispatchEvent(new Event('change', { bubbles: true }));
        password.dispatchEvent(new Event('change', { bubbles: true }));
        form.requestSubmit();
      JS
    else
      page.driver.post sessions_path, { session: { email: user.email, password: "password" } }
    end

    assert_no_current_path new_session_path, wait: 5
  end

  def js_system_tests_enabled?
    self.class::JS_SYSTEM_TESTS_ENABLED
  end
end
