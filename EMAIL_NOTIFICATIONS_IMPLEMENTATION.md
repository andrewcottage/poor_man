# Email Notifications for New Recipes

## Overview

This implementation adds email notifications for new recipes with user opt-in/opt-out functionality using Rails primitives and assumes SES for delivery.

## Features Implemented

### 1. Database Changes
- Added `notify_new_recipes` boolean column to users table (defaults to `true`)
- Migration: `db/migrate/20250102120000_add_notification_preferences_to_users.rb`

### 2. User Model Updates
- Added notification preference attribute to User model
- Default value is `true` (users are opted in by default)

### 3. Email System
- **Mailer**: `app/mailers/recipe_mailer.rb`
  - `new_recipe_notification` method for sending notifications
  - Uses "notifications@poorman.com" as sender
- **Email Templates**: 
  - HTML: `app/views/recipe_mailer/new_recipe_notification.html.erb`
  - Text: `app/views/recipe_mailer/new_recipe_notification.text.erb`
  - Professional styling with recipe details and unsubscribe link

### 4. Background Processing
- **Job**: `app/jobs/new_recipe_notification_job.rb`
  - Sends notifications to all opted-in users
  - Excludes the recipe author from notifications
  - Uses `find_each` for efficient batch processing

### 5. Recipe Integration
- Added `after_create` callback to Recipe model
- Automatically enqueues notification job when new recipe is created
- Uses `perform_later` for asynchronous processing

### 6. User Interface
- **Profile Form**: `app/views/profiles/_user_form.html.erb`
  - Checkbox for "New Recipe Notifications"
  - Professional styling with Tailwind CSS
  - Clear description of what notifications include
- **Profile Edit Page**: Updated to use the new form
- **Controller**: Updated ProfilesController to permit the new parameter

### 7. Testing
- **Unit Tests**:
  - User model tests for notification preference
  - Mailer tests for email content and delivery
  - Job tests for notification logic
- **Integration Tests**:
  - Complete flow testing for notification preferences
  - Recipe creation and notification sending
  - Opt-out functionality verification

## How It Works

1. **User Registration**: New users are opted in by default (`notify_new_recipes: true`)

2. **Recipe Creation**: When a new recipe is created:
   - Recipe model triggers `after_create` callback
   - `NewRecipeNotificationJob` is enqueued
   - Job runs in background and sends emails to opted-in users

3. **User Preferences**: Users can opt in/out via their profile settings:
   - Navigate to Profile → Edit Profile
   - Toggle "New Recipe Notifications" checkbox
   - Changes are saved immediately

4. **Email Content**: Notifications include:
   - Recipe title and description
   - Category, difficulty, prep time, and cost
   - Author information
   - Direct link to view the recipe
   - Unsubscribe link

## Email Delivery Configuration

The system assumes AWS SES for email delivery. To configure:

1. Set up AWS SES credentials in your Rails application
2. Configure Action Mailer in your environment files:

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :aws_ses
config.action_mailer.default_url_options = { host: 'your-domain.com' }
```

## Key Benefits

- **User Control**: Users can easily opt in/out of notifications
- **Performance**: Background job processing prevents blocking recipe creation
- **Scalability**: Efficient batch processing with `find_each`
- **Professional**: Well-designed email templates with proper styling
- **Rails Convention**: Uses standard Rails patterns and conventions
- **Tested**: Comprehensive test coverage for all functionality

## Files Created/Modified

### New Files
- `db/migrate/20250102120000_add_notification_preferences_to_users.rb`
- `app/mailers/recipe_mailer.rb`
- `app/views/recipe_mailer/new_recipe_notification.html.erb`
- `app/views/recipe_mailer/new_recipe_notification.text.erb`
- `app/jobs/new_recipe_notification_job.rb`
- `test/mailers/recipe_mailer_test.rb`
- `test/jobs/new_recipe_notification_job_test.rb`
- `test/integration/recipe_notification_flow_test.rb`

### Modified Files
- `app/models/user.rb` - Added notification preference attribute
- `app/models/recipe.rb` - Added after_create callback
- `app/controllers/profiles_controller.rb` - Added notification parameter
- `app/views/profiles/_user_form.html.erb` - Added notification toggle
- `app/views/profiles/edit.html.erb` - Updated layout
- `test/models/user_test.rb` - Added notification tests
- `test/fixtures/users.yml` - Added notification field to fixtures

## Usage

1. Run the migration: `rails db:migrate`
2. Users can now update their notification preferences in their profile
3. When recipes are created, notifications will be sent automatically
4. Monitor background job processing for email delivery