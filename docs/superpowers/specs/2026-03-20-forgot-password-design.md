# Forgot Password Flow — Design Spec

## Overview

Add a password reset flow to Stovaro so users can recover access when they forget their password. Uses Rails 8's `generates_token_for` for signed, self-expiring tokens — no extra DB columns needed.

## User Flow

1. User clicks "Forgot password?" on the login page → `GET /password_resets/new`
2. User enters their email address and submits → `POST /password_resets`
3. Controller always renders a "Check your email" confirmation page (never reveals whether the email exists in the system)
4. If a user with that email exists, `UserMailer.password_reset(user)` is enqueued via `deliver_later` (Solid Queue)
5. Email contains a link with a signed token: `GET /password_resets/{token}/edit`
6. User clicks the link → form to enter new password + password confirmation
7. User submits → `PATCH /password_resets/{token}` → password is updated, user is signed in, redirected to root with a flash notice

## Token Strategy

- `generates_token_for :password_reset, expires_in: 15.minutes` added to the User model
- Token is derived from the user's `password_digest`, so it auto-invalidates if the password changes before the token is used
- No additional database columns required — the existing unused `recovery_digest` column remains unused
- Token is embedded in the URL, not stored server-side

## OAuth Users

OAuth-only users (Google sign-in) who request a reset will not receive an email. The `create` action skips sending when `user.provider.present?` — but still shows the same generic "Check your email" page to prevent email enumeration.

## New Files

### `app/controllers/password_resets_controller.rb`

Four actions:

- `new` — renders the email input form
- `create` — looks up user by email (using model `normalizes` for case-insensitive lookup); if found and not OAuth-only, enqueues reset email; always renders confirmation page
- `edit` — resolves user from token via `User.find_by_token_for(:password_reset, params[:token])`; if invalid/expired, redirects to `new` with flash alert
- `update` — resolves user from token; calls `reset_session` to prevent session fixation; updates password (validates presence and confirmation); signs user in via `session[:user_id] = user.id`; redirects to root

### `app/mailers/user_mailer.rb`

- `password_reset(user)` method
- Generates token via `user.generate_token_for(:password_reset)`
- Builds reset URL: `edit_password_reset_url(token)`
- Subject: "Reset your Stovaro password"

### `app/views/password_resets/new.html.erb`

- Centered card layout matching the login page aesthetic
- Single email input field
- "Send reset link" submit button
- Link back to sign in page

### `app/views/password_resets/create.html.erb`

- "Check your email" confirmation page
- Shows the same message regardless of whether email exists
- Includes a link back to sign in

### `app/views/password_resets/edit.html.erb`

- Centered card layout matching the login page aesthetic
- Password field + password confirmation field
- "Reset password" submit button
- Token is in the URL via the route param

### `app/views/user_mailer/password_reset.html.erb`

- Simple, clean email with Stovaro branding
- Reset link button
- "This link expires in 15 minutes" notice
- "If you didn't request this, you can ignore this email"

### `app/views/user_mailer/password_reset.text.erb`

- Plain text version of the same content

## Modified Files

### `app/models/user.rb`

Add:
```ruby
generates_token_for :password_reset, expires_in: 15.minutes do
  password_digest
end
```

### `app/views/sessions/new.html.erb`

Change the "Forgot password?" link from `'#'` to `new_password_reset_path`.

### `config/routes.rb`

Add:
```ruby
resources :password_resets, param: :token, only: %i[new create edit update]
```

Note: `param: :token` so routes use `:token` instead of `:id`, matching the semantic meaning.

### `app/mailers/application_mailer.rb`

Update the default `from` address from `"from@example.com"` to `"noreply@stovaro.com"`.

## Email Delivery

- Uses `deliver_later` which routes through Solid Queue for async delivery
- Production: AWS SES (SMTP configuration needed in production environment)
- Development: Rails default (letter_opener or log delivery)

## Security Considerations

- **No email enumeration**: `create` action always shows the same confirmation page regardless of whether the email exists
- **15-minute expiry**: Short window limits exposure if a reset link is intercepted
- **Auto-invalidation**: Token becomes invalid the moment the password changes (because token is derived from `password_digest`)
- **Session fixation prevention**: `reset_session` is called before setting the new session after password update
- **HTTPS required**: Production serves over HTTPS via Kamal/Thruster — tokens in URLs are protected in transit
- **OAuth guard**: OAuth-only users do not receive reset emails (no password to reset)

## Password Validation

The `update` action validates:
- Password is present (not blank)
- Password confirmation matches
- Minimum 6 characters (enforced via model validation)

On validation failure, re-renders the `edit` form with errors.

## Tests

### `test/controllers/password_resets_controller_test.rb`

- `GET /password_resets/new` renders the form
- `POST /password_resets` with valid email enqueues a mailer job
- `POST /password_resets` with unknown email still renders confirmation (no enumeration)
- `POST /password_resets` with OAuth user email does not enqueue email, still renders confirmation
- `GET /password_resets/:token/edit` with valid token renders the password form
- `GET /password_resets/:token/edit` with expired/invalid token redirects to `new` with alert
- `PATCH /password_resets/:token` with valid token and matching passwords updates the password and signs in
- `PATCH /password_resets/:token` with valid token and mismatched passwords re-renders the form
- `PATCH /password_resets/:token` with valid token and blank password re-renders the form
- `PATCH /password_resets/:token` with invalid token redirects to `new`
- `PATCH /password_resets/:token` — token cannot be reused after successful reset (auto-invalidation)

### `test/mailers/user_mailer_test.rb`

- Email is sent to the correct recipient
- Email contains the reset link
- Email subject is correct
- `deliver_later` is used (not `deliver_now`)

## Out of Scope

- Rate limiting on reset requests (fast-follow — recommend `rack-attack` throttle on `POST /password_resets`)
- Account lockout
- "Password changed" confirmation email (fast-follow)
- Password strength requirements beyond 6-character minimum
