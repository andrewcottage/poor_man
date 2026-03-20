# Forgot Password Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users reset their password via email when they forget it.

**Architecture:** Rails 8's `generates_token_for` creates signed, self-expiring tokens derived from `password_digest` — no DB migration needed. A `PasswordResetsController` handles the 4-step flow (request form → send email → new password form → update). `UserMailer` sends the reset link via `deliver_later` (Solid Queue). OAuth-only users are silently skipped.

**Tech Stack:** Rails 8.1, `generates_token_for`, ActionMailer, Solid Queue, Minitest, Tailwind CSS

---

## File Map

| Action | Path | Responsibility |
|--------|------|---------------|
| Create | `app/controllers/password_resets_controller.rb` | 4 RESTful actions for the reset flow |
| Create | `app/mailers/user_mailer.rb` | `password_reset` mailer method |
| Create | `app/views/password_resets/new.html.erb` | Email input form |
| Create | `app/views/password_resets/create.html.erb` | "Check your email" confirmation |
| Create | `app/views/password_resets/edit.html.erb` | New password form |
| Create | `app/views/user_mailer/password_reset.html.erb` | HTML email template |
| Create | `app/views/user_mailer/password_reset.text.erb` | Plain text email template |
| Create | `test/controllers/password_resets_controller_test.rb` | Integration tests |
| Create | `test/mailers/user_mailer_test.rb` | Mailer tests |
| Modify | `app/models/user.rb:40` | Add `generates_token_for :password_reset` + password length validation |
| Modify | `config/routes.rb:71` | Add `resources :password_resets` |
| Modify | `config/environments/test.rb` | Add `default_url_options` for mailer URL helpers |
| Modify | `app/views/sessions/new.html.erb:34` | Wire "Forgot password?" link |
| Modify | `app/mailers/application_mailer.rb:2` | Update default `from` address |

---

## Chunk 1: Model + Route + Mailer Foundation

### Task 1: Add `generates_token_for` and password length validation to User model

**Files:**
- Modify: `app/models/user.rb:40`
- Create: `test/models/user_password_reset_token_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/models/user_password_reset_token_test.rb`:

```ruby
require "test_helper"

class UserPasswordResetTokenTest < ActiveSupport::TestCase
  setup do
    @user = users(:user)
  end

  test "generates a password reset token" do
    token = @user.generate_token_for(:password_reset)
    assert_not_nil token
    assert_kind_of String, token
  end

  test "resolves user from valid token" do
    token = @user.generate_token_for(:password_reset)
    resolved = User.find_by_token_for(:password_reset, token)
    assert_equal @user, resolved
  end

  test "returns nil for invalid token" do
    resolved = User.find_by_token_for(:password_reset, "bogus-token")
    assert_nil resolved
  end

  test "token is invalidated after password change" do
    token = @user.generate_token_for(:password_reset)
    @user.update!(password: "newpassword123", password_confirmation: "newpassword123")
    resolved = User.find_by_token_for(:password_reset, token)
    assert_nil resolved
  end

  test "token expires after 15 minutes" do
    token = @user.generate_token_for(:password_reset)
    travel 16.minutes do
      resolved = User.find_by_token_for(:password_reset, token)
      assert_nil resolved
    end
  end

  test "rejects password shorter than 6 characters" do
    @user.password = "short"
    @user.password_confirmation = "short"
    assert_not @user.valid?
    assert_includes @user.errors[:password], "is too short (minimum is 6 characters)"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/models/user_password_reset_token_test.rb`
Expected: FAIL — `generates_token_for` not yet defined, and no password length validation.

- [ ] **Step 3: Add generates_token_for and password validation to User model**

In `app/models/user.rb`, after line 40 (`has_secure_password`), add:

```ruby
generates_token_for :password_reset, expires_in: 15.minutes do
  password_digest
end
```

After line 45 (`validates :username, presence: true, uniqueness: true`), add:

```ruby
validates :password, length: { minimum: 6 }, allow_nil: true
```

Note: `allow_nil: true` is needed because `has_secure_password` sets password to nil on reload, and we only want to validate length when a password is actually being set.

- [ ] **Step 4: Run test to verify it passes**

Run: `bundle exec rails test test/models/user_password_reset_token_test.rb`
Expected: 6 tests, 0 failures.

- [ ] **Step 5: Commit**

```bash
git add app/models/user.rb test/models/user_password_reset_token_test.rb
git commit -m "Add generates_token_for :password_reset and password length validation"
```

---

### Task 2: Add route, update ApplicationMailer, configure mailer URL options for test

**Files:**
- Modify: `config/routes.rb:71` (line 71 is `resources :sessions`)
- Modify: `app/mailers/application_mailer.rb:2`
- Modify: `config/environments/test.rb`

- [ ] **Step 1: Add the password_resets route**

In `config/routes.rb`, after `resources :sessions, only: %i[new create destroy]` (line 71), add:

```ruby
resources :password_resets, param: :token, only: %i[new create edit update]
```

- [ ] **Step 2: Update ApplicationMailer default from address**

In `app/mailers/application_mailer.rb`, change line 2 from:

```ruby
default from: "from@example.com"
```

to:

```ruby
default from: "noreply@stovaro.com"
```

- [ ] **Step 3: Add default_url_options for mailer in test environment**

In `config/environments/test.rb`, after the `config.action_mailer.delivery_method = :test` line (line 50), add:

```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

This is required for URL helpers like `edit_password_reset_url` used in the mailer templates and tests.

- [ ] **Step 4: Verify routes exist**

Run: `bundle exec rails routes -g password_reset`
Expected output should show 4 routes:
- `GET /password_resets/new` → `password_resets#new`
- `POST /password_resets` → `password_resets#create`
- `GET /password_resets/:token/edit` → `password_resets#edit`
- `PATCH /password_resets/:token` → `password_resets#update`

- [ ] **Step 5: Commit**

```bash
git add config/routes.rb app/mailers/application_mailer.rb config/environments/test.rb
git commit -m "Add password_resets routes, update mailer from address, configure test URL options"
```

---

### Task 3: Create UserMailer

**Files:**
- Create: `app/mailers/user_mailer.rb`
- Create: `app/views/user_mailer/password_reset.html.erb`
- Create: `app/views/user_mailer/password_reset.text.erb`
- Create: `test/mailers/user_mailer_test.rb`

- [ ] **Step 1: Write the failing mailer test**

Create `test/mailers/user_mailer_test.rb`:

```ruby
require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:user)
    @token = @user.generate_token_for(:password_reset)
  end

  test "password_reset email is sent to the correct recipient" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal [ @user.email ], email.to
  end

  test "password_reset email has correct subject" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal "Reset your Stovaro password", email.subject
  end

  test "password_reset email contains reset link" do
    email = UserMailer.password_reset(@user, @token)
    assert_match edit_password_reset_url(@token), email.body.encoded
  end

  test "password_reset email contains expiry notice" do
    email = UserMailer.password_reset(@user, @token)
    assert_match "15 minutes", email.body.encoded
  end

  test "password_reset email is sent from noreply@stovaro.com" do
    email = UserMailer.password_reset(@user, @token)
    assert_equal [ "noreply@stovaro.com" ], email.from
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/mailers/user_mailer_test.rb`
Expected: FAIL — `UserMailer` is not defined.

- [ ] **Step 3: Create the UserMailer**

Create `app/mailers/user_mailer.rb`:

```ruby
class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user = user
    @token = token
    mail to: user.email, subject: "Reset your Stovaro password"
  end
end
```

- [ ] **Step 4: Create the HTML email template**

Create `app/views/user_mailer/password_reset.html.erb`:

```erb
<div style="max-width: 480px; margin: 0 auto; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; color: #1e293b;">
  <h2 style="font-size: 20px; font-weight: 600; margin-bottom: 16px;">Reset your password</h2>

  <p style="font-size: 14px; line-height: 1.6; color: #475569;">
    Hi <%= @user.name || @user.username %>, we received a request to reset the password for your Stovaro account.
  </p>

  <div style="margin: 24px 0; text-align: center;">
    <%= link_to "Reset my password",
        edit_password_reset_url(@token),
        style: "display: inline-block; padding: 12px 24px; background-color: #059669; color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 14px; font-weight: 600;" %>
  </div>

  <p style="font-size: 13px; line-height: 1.6; color: #64748b;">
    This link expires in <strong>15 minutes</strong>. If you didn't request a password reset, you can safely ignore this email.
  </p>

  <hr style="border: none; border-top: 1px solid #e2e8f0; margin: 24px 0;">

  <p style="font-size: 12px; color: #94a3b8;">
    If the button doesn't work, copy and paste this URL into your browser:<br>
    <%= edit_password_reset_url(@token) %>
  </p>
</div>
```

- [ ] **Step 5: Create the plain text email template**

Create `app/views/user_mailer/password_reset.text.erb`:

```erb
Reset your password
====================

Hi <%= @user.name || @user.username %>, we received a request to reset the password for your Stovaro account.

Reset your password by visiting this link:

<%= edit_password_reset_url(@token) %>

This link expires in 15 minutes. If you didn't request a password reset, you can safely ignore this email.
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bundle exec rails test test/mailers/user_mailer_test.rb`
Expected: 5 tests, 5 assertions, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add app/mailers/user_mailer.rb app/views/user_mailer/ test/mailers/user_mailer_test.rb
git commit -m "Add UserMailer with password reset email"
```

---

## Chunk 2: Controller + Views

### Task 4: Create PasswordResetsController with `new` and `create` actions

**Files:**
- Create: `app/controllers/password_resets_controller.rb`
- Create: `app/views/password_resets/new.html.erb`
- Create: `app/views/password_resets/create.html.erb`
- Create: `test/controllers/password_resets_controller_test.rb`

- [ ] **Step 1: Write the failing tests for `new` and `create`**

Create `test/controllers/password_resets_controller_test.rb`:

```ruby
require "test_helper"

class PasswordResetsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:user)
  end

  test "GET new renders the email form" do
    get new_password_reset_url
    assert_response :success
    assert_select "h2", text: "Reset your password"
    assert_select "input[type='email']"
  end

  test "POST create with valid email enqueues reset email and renders confirmation" do
    assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: @user.email }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end

  test "POST create with unknown email still renders confirmation" do
    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: "nobody@example.com" }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end

  test "POST create with OAuth user email does not enqueue email" do
    oauth_user = users(:andrew)
    oauth_user.update_columns(provider: "google_oauth2")

    assert_no_enqueued_jobs(only: ActionMailer::MailDeliveryJob) do
      post password_resets_url, params: { email: oauth_user.email }
    end
    assert_response :success
    assert_select "h2", text: "Check your email"
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bundle exec rails test test/controllers/password_resets_controller_test.rb`
Expected: FAIL — `PasswordResetsController` is not defined.

- [ ] **Step 3: Create the controller with `new` and `create`**

Create `app/controllers/password_resets_controller.rb`:

```ruby
class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user.present? && user.provider.blank?
      token = user.generate_token_for(:password_reset)
      UserMailer.password_reset(user, token).deliver_later
    end

    render :create
  end

  def edit
  end

  def update
  end
end
```

- [ ] **Step 4: Create the `new` view (email form)**

Create `app/views/password_resets/new.html.erb`:

```erb
<div class="flex min-h-full min-w-full flex-col justify-center py-6 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <h2 class="mt-6 text-center text-2xl font-bold leading-9 tracking-tight text-slate-900">Reset your password</h2>
    <p class="mt-2 text-center text-sm text-slate-600">Enter your email and we'll send you a link to reset your password.</p>
  </div>

  <div class="mt-10 sm:mx-auto sm:w-full sm:max-w-[480px]">
    <div class="stovaro-surface px-6 py-12 sm:px-12">
      <%= form_with url: password_resets_path, method: :post, class: "space-y-6" do |f| %>
        <div>
          <%= f.label :email, "Email address", class: "stovaro-label leading-6" %>
          <div class="mt-2">
            <%= f.email_field :email, required: true, autofocus: true, class: "block w-full rounded-xl border-0 py-2 text-slate-900 shadow-sm ring-1 ring-inset ring-stone-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-emerald-600 sm:text-sm sm:leading-6" %>
          </div>
        </div>

        <div>
          <%= f.submit "Send reset link", class: "stovaro-btn-primary flex w-full" %>
        </div>
      <% end %>
    </div>

    <p class="mt-10 text-center text-sm text-slate-500">
      Remember your password?
      <%= link_to "Sign in", new_session_path, class: "font-semibold leading-6 text-emerald-700 hover:text-emerald-600" %>
    </p>
  </div>
</div>
```

- [ ] **Step 5: Create the `create` view (confirmation)**

Create `app/views/password_resets/create.html.erb`:

```erb
<div class="flex min-h-full min-w-full flex-col justify-center py-6 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-emerald-100">
      <svg class="h-6 w-6 text-emerald-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
      </svg>
    </div>
    <h2 class="mt-6 text-center text-2xl font-bold leading-9 tracking-tight text-slate-900">Check your email</h2>
    <p class="mt-2 text-center text-sm text-slate-600">If an account exists with that email, we've sent a password reset link. It expires in 15 minutes.</p>
  </div>

  <div class="mt-10 text-center">
    <%= link_to "Back to sign in", new_session_path, class: "font-semibold text-sm text-emerald-700 hover:text-emerald-600" %>
  </div>
</div>
```

- [ ] **Step 6: Run test to verify it passes**

Run: `bundle exec rails test test/controllers/password_resets_controller_test.rb`
Expected: 4 tests, 0 failures.

- [ ] **Step 7: Commit**

```bash
git add app/controllers/password_resets_controller.rb app/views/password_resets/new.html.erb app/views/password_resets/create.html.erb test/controllers/password_resets_controller_test.rb
git commit -m "Add password reset request flow (new + create actions)"
```

---

### Task 5: Add `edit` and `update` actions

**Files:**
- Modify: `app/controllers/password_resets_controller.rb`
- Create: `app/views/password_resets/edit.html.erb`
- Modify: `test/controllers/password_resets_controller_test.rb`

- [ ] **Step 1: Write the failing tests for `edit` and `update`**

Append to `test/controllers/password_resets_controller_test.rb` (inside the class, after the existing tests):

```ruby
  test "GET edit with valid token renders new password form" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_reset_url(token)
    assert_response :success
    assert_select "h2", text: "Set your new password"
    assert_select "input[type='password']", count: 2
  end

  test "GET edit with invalid token redirects to new with alert" do
    get edit_password_reset_url("invalid-token")
    assert_redirected_to new_password_reset_url
    assert_equal "That reset link is invalid or has expired.", flash[:alert]
  end

  test "PATCH update with valid token and matching passwords updates password and signs in" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to root_url
    assert_equal "Your password has been reset.", flash[:notice]
    assert_equal @user.id, session[:user_id]
    assert @user.reload.authenticate("newsecurepassword")
  end

  test "PATCH update with mismatched passwords re-renders form" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "different"
    }
    assert_response :unprocessable_entity
    assert_select "h2", text: "Set your new password"
  end

  test "PATCH update with blank password re-renders form" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "",
      password_confirmation: ""
    }
    assert_response :unprocessable_entity
    assert_select "h2", text: "Set your new password"
  end

  test "PATCH update with invalid token redirects to new" do
    patch password_reset_url("invalid-token"), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to new_password_reset_url
    assert_equal "That reset link is invalid or has expired.", flash[:alert]
  end

  test "token cannot be reused after successful reset" do
    token = @user.generate_token_for(:password_reset)
    patch password_reset_url(token), params: {
      password: "newsecurepassword",
      password_confirmation: "newsecurepassword"
    }
    assert_redirected_to root_url

    # Try to reuse the same token
    get edit_password_reset_url(token)
    assert_redirected_to new_password_reset_url
  end
```

- [ ] **Step 2: Run test to verify the new tests fail**

Run: `bundle exec rails test test/controllers/password_resets_controller_test.rb`
Expected: The 4 existing tests pass. The 7 new tests fail because `edit` and `update` are empty stubs.

- [ ] **Step 3: Implement `edit` and `update` in the controller**

Replace the `edit` and `update` stubs in `app/controllers/password_resets_controller.rb`:

```ruby
class PasswordResetsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: params[:email])

    if user.present? && user.provider.blank?
      token = user.generate_token_for(:password_reset)
      UserMailer.password_reset(user, token).deliver_later
    end

    render :create
  end

  def edit
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_url, alert: "That reset link is invalid or has expired."
      return
    end
  end

  def update
    @user = User.find_by_token_for(:password_reset, params[:token])

    unless @user
      redirect_to new_password_reset_url, alert: "That reset link is invalid or has expired."
      return
    end

    if @user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      reset_session
      session[:user_id] = @user.id
      redirect_to root_url, notice: "Your password has been reset."
    else
      render :edit, status: :unprocessable_entity
    end
  end
end
```

- [ ] **Step 4: Create the `edit` view (new password form)**

Create `app/views/password_resets/edit.html.erb`:

```erb
<div class="flex min-h-full min-w-full flex-col justify-center py-6 sm:px-6 lg:px-8">
  <div class="sm:mx-auto sm:w-full sm:max-w-md">
    <h2 class="mt-6 text-center text-2xl font-bold leading-9 tracking-tight text-slate-900">Set your new password</h2>
  </div>

  <div class="mt-10 sm:mx-auto sm:w-full sm:max-w-[480px]">
    <div class="stovaro-surface px-6 py-12 sm:px-12">
      <% if @user.errors.any? %>
        <div class="mb-6 rounded-lg bg-red-50 p-4">
          <ul class="list-disc pl-5 text-sm text-red-700">
            <% @user.errors.full_messages.each do |message| %>
              <li><%= message %></li>
            <% end %>
          </ul>
        </div>
      <% end %>

      <%= form_with url: password_reset_path(params[:token]), method: :patch, class: "space-y-6" do |f| %>
        <div>
          <%= f.label :password, "New password", class: "stovaro-label leading-6" %>
          <div class="mt-2">
            <%= f.password_field :password, required: true, autofocus: true, autocomplete: "new-password", class: "block w-full rounded-xl border-0 py-2 text-slate-900 shadow-sm ring-1 ring-inset ring-stone-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-emerald-600 sm:text-sm sm:leading-6" %>
          </div>
        </div>

        <div>
          <%= f.label :password_confirmation, "Confirm new password", class: "stovaro-label leading-6" %>
          <div class="mt-2">
            <%= f.password_field :password_confirmation, required: true, autocomplete: "new-password", class: "block w-full rounded-xl border-0 py-2 text-slate-900 shadow-sm ring-1 ring-inset ring-stone-300 placeholder:text-slate-400 focus:ring-2 focus:ring-inset focus:ring-emerald-600 sm:text-sm sm:leading-6" %>
          </div>
        </div>

        <div>
          <%= f.submit "Reset password", class: "stovaro-btn-primary flex w-full" %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bundle exec rails test test/controllers/password_resets_controller_test.rb`
Expected: 11 tests, 0 failures.

- [ ] **Step 6: Commit**

```bash
git add app/controllers/password_resets_controller.rb app/views/password_resets/edit.html.erb test/controllers/password_resets_controller_test.rb
git commit -m "Add password reset edit + update actions with token validation"
```

---

## Chunk 3: Wire Up Login Page + Full Suite

### Task 6: Wire "Forgot password?" link on login page

**Files:**
- Modify: `app/views/sessions/new.html.erb:34`

- [ ] **Step 1: Update the link**

In `app/views/sessions/new.html.erb`, change line 34 from:

```erb
<%= link_to 'Forgot password?', '#', class: 'font-semibold text-emerald-700 hover:text-emerald-600' %>
```

to:

```erb
<%= link_to 'Forgot password?', new_password_reset_path, class: 'font-semibold text-emerald-700 hover:text-emerald-600' %>
```

- [ ] **Step 2: Verify the link works in an existing test**

Run: `bundle exec rails test test/controllers/sessions_controller_test.rb`
Expected: All existing session tests still pass.

- [ ] **Step 3: Commit**

```bash
git add app/views/sessions/new.html.erb
git commit -m "Wire forgot password link on login page"
```

---

### Task 7: Run full test suite

- [ ] **Step 1: Run all tests**

Run: `bundle exec rails test`
Expected: All tests pass, 0 failures, 0 errors.

- [ ] **Step 2: Run linter**

Run: `bundle exec rubocop app/controllers/password_resets_controller.rb app/mailers/user_mailer.rb app/models/user.rb test/controllers/password_resets_controller_test.rb test/mailers/user_mailer_test.rb test/models/user_password_reset_token_test.rb`
Expected: No offenses detected. If any, fix them.

- [ ] **Step 3: Fix any lint issues and commit if needed**

```bash
git add -A
git commit -m "Fix lint issues in password reset flow"
```

(Skip this step if no lint issues.)
