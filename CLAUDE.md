# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Stovaro** is a Rails 8.1 recipe discovery, AI generation, and meal planning app. Server-rendered HTML with Hotwire (Turbo + Stimulus), Tailwind CSS, SQLite, and no Node.js build step (ImportMap).

- Ruby 4.0.1, Rails 8.1 (edge, from GitHub main branch)
- Database: SQLite3 (multi-database in production: primary, cable, cache, queue via Solid Stack)
- Auth: bcrypt sessions + OmniAuth Google OAuth2
- AI: OpenAI (ruby-openai) for recipe generation
- Payments: Stripe integration
- Deployment: Docker + Kamal + Thruster

## Common Commands

```bash
# Development
bin/dev                          # Start Rails server + Tailwind watcher (via foreman)
bin/setup                        # Install deps, prepare DB, clear logs

# Testing
bundle exec rails test           # Run all tests
bundle exec rails test test/models/recipe_test.rb          # Single file
bundle exec rails test test/models/recipe_test.rb -n test_name  # Single test
bundle exec rails test test/system/  # System tests (Capybara + Selenium/Chrome)

# Linting
bundle exec rubocop              # Lint (rubocop-rails-omakase preset)
bundle exec rubocop -A           # Auto-fix

# Database
bin/rails db:prepare             # Create + migrate + seed
bin/rails db:migrate
bin/rails db:seed

# Assets
bin/rails tailwindcss:build      # One-off Tailwind build (CI uses this)
```

## Architecture

### Backend Patterns

- **Current pattern**: `Current.user` provides thread-safe user context (set in `ApplicationController`)
- **Service objects** in `app/services/` for complex logic: recipe parsing/scaling (`Recipe::IngredientParser`, `Recipe::QuantityMath`, `Recipe::IngredientScaler`), nutrition estimation, grocery list building, billing, community feed
- **Model modules** in `app/models/recipe/` for shared recipe behavior: `Favoritable`, `Ratable`, `Editable`, `Stars`, `Taggable`, `ImageGeneration`
- **Background jobs** via Solid Queue: recipe generation pipeline in `app/jobs/recipe/generation/` (data, instructions, images)
- **API endpoints** under `Api::` namespace with Bearer token or `X-Api-Key` auth

### Frontend Patterns

- **Turbo Frames** for partial page updates, **Turbo Streams** for reactive CRUD
- **Stimulus controllers** in `app/javascript/controllers/` (account dropdown, cook mode, generation status polling, gallery, clipboard, mobile menu, slug)
- **Tailwind CSS** only -- no custom CSS files
- **ImportMap** for JS module loading (no webpack/esbuild)

### Key Models

Recipe is the central model. Related: `Recipe::Generation` (AI-generated pending approval), `Category`, `Tag`/`Tagging`, `Favorite`, `Rating`, `Collection`, `MealPlan`/`PlannedMeal`, `GroceryList`/`GroceryListItem`, `UserFollow`, `Subscription`, `CreditPurchase`.

### Routing

Recipes use `:slug` param. Cooks use `:username` param. Namespaced under `profiles/` (meal plans, collections, grocery lists), `billing/` (checkout, Stripe webhooks), `admin/` (recipe submission moderation), `recipes/` (generations), `api/` (JSON).

### Testing

- Minitest with fixtures (not FactoryBot despite what `.claude-instructions.md` says)
- Mocha for mocking/stubbing
- System tests use Capybara + Selenium with Chrome
- Test helpers: `login(user)` for integration tests, `sign_in_as(user)` for system tests

### CI

GitHub Actions (`.github/workflows/ruby.yml`): lint job (rubocop) + test job (tailwindcss:build, db:prepare, rails test). Runs on push to main and PRs.

## Conventions

See `.claude-instructions.md` for detailed Rails development guidelines. Key points:
- Server-rendered ERB with Hotwire, not React/Vue
- Service objects for complex business logic
- Stimulus for JS interactivity, keep controllers thin
- Tailwind utility classes, no custom CSS
- Partials for view reusability
- Ruby 3+ syntax (safe navigation, numbered blocks, implicit forwarding)
