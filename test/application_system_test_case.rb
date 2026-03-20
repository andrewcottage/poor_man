require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  def sign_in_as(user)
    # Navigate to blank page to fully clear Turbo cache
    page.driver.browser.navigate.to("about:blank")
    sleep 0.2

    visit new_session_url
    assert_selector "h2", text: "Sign in to your account", wait: 5

    # Use JavaScript to fill and submit form atomically to avoid Turbo morph race conditions
    page.execute_script(<<~JS, user.email)
      const form = document.querySelector('form');
      const email = form.querySelector('input[name="session[email]"]');
      const password = form.querySelector('input[name="session[password]"]');
      email.value = arguments[0];
      password.value = 'password';
      // Dispatch input events so any JS listeners are triggered
      email.dispatchEvent(new Event('input', { bubbles: true }));
      password.dispatchEvent(new Event('input', { bubbles: true }));
      email.dispatchEvent(new Event('change', { bubbles: true }));
      password.dispatchEvent(new Event('change', { bubbles: true }));
      form.requestSubmit();
    JS

    assert_no_current_path new_session_path, wait: 5
  end
end
