# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_20_101500) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analytics_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_name", null: false
    t.text "metadata"
    t.string "path"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["created_at"], name: "index_analytics_events_on_created_at"
    t.index ["event_name"], name: "index_analytics_events_on_event_name"
    t.index ["user_id"], name: "index_analytics_events_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "recipies_count"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "chat_conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_chat_conversations_on_user_id"
  end

  create_table "chat_messages", force: :cascade do |t|
    t.text "content"
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.string "tool_call_id"
    t.text "tool_calls"
    t.string "tool_name"
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_chat_messages_on_conversation_id"
  end

  create_table "collection_recipes", force: :cascade do |t|
    t.integer "collection_id", null: false
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "recipe_id"], name: "index_collection_recipes_on_collection_id_and_recipe_id", unique: true
    t.index ["collection_id"], name: "index_collection_recipes_on_collection_id"
    t.index ["recipe_id"], name: "index_collection_recipes_on_recipe_id"
  end

  create_table "collections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_collections_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_collections_on_user_id"
  end

  create_table "credit_purchases", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "credited_at"
    t.integer "credits", null: false
    t.string "pack_id", null: false
    t.text "payload"
    t.integer "status", default: 0, null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_customer_id"
    t.string "stripe_payment_intent_id"
    t.string "stripe_price_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["pack_id"], name: "index_credit_purchases_on_pack_id"
    t.index ["stripe_checkout_session_id"], name: "index_credit_purchases_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_credit_purchases_on_stripe_payment_intent_id"
    t.index ["user_id"], name: "index_credit_purchases_on_user_id"
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["recipe_id"], name: "index_favorites_on_recipe_id"
    t.index ["user_id", "recipe_id"], name: "index_favorites_on_user_id_and_recipe_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "grocery_list_items", force: :cascade do |t|
    t.string "aisle", default: "Pantry", null: false
    t.boolean "checked", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "grocery_list_id", null: false
    t.string "name", null: false
    t.string "notes"
    t.integer "position", default: 1, null: false
    t.string "quantity"
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["grocery_list_id", "aisle", "position"], name: "index_grocery_list_items_on_grouping"
    t.index ["grocery_list_id"], name: "index_grocery_list_items_on_grocery_list_id"
  end

  create_table "grocery_lists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "generated_at"
    t.integer "meal_plan_id", null: false
    t.string "share_token", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["meal_plan_id"], name: "index_grocery_lists_on_meal_plan_id", unique: true
    t.index ["share_token"], name: "index_grocery_lists_on_share_token", unique: true
    t.index ["user_id"], name: "index_grocery_lists_on_user_id"
  end

  create_table "meal_plans", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.date "week_of", null: false
    t.index ["user_id", "week_of"], name: "index_meal_plans_on_user_id_and_week_of", unique: true
    t.index ["user_id"], name: "index_meal_plans_on_user_id"
  end

  create_table "planned_meals", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "meal_plan_id", null: false
    t.integer "meal_type", default: 2, null: false
    t.integer "position", default: 1, null: false
    t.integer "recipe_id", null: false
    t.date "scheduled_on", null: false
    t.datetime "updated_at", null: false
    t.index ["meal_plan_id", "scheduled_on", "meal_type", "position"], name: "index_planned_meals_on_calendar_slot"
    t.index ["meal_plan_id"], name: "index_planned_meals_on_meal_plan_id"
    t.index ["recipe_id"], name: "index_planned_meals_on_recipe_id"
  end

  create_table "pro_waitlist_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "plan_preference"
    t.string "source"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["email"], name: "index_pro_waitlist_entries_on_email", unique: true
    t.index ["user_id"], name: "index_pro_waitlist_entries_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.text "comment", limit: 200
    t.datetime "created_at", null: false
    t.integer "recipe_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value", null: false
    t.index ["recipe_id", "user_id"], name: "index_ratings_on_recipe_id_and_user_id", unique: true
    t.index ["recipe_id"], name: "index_ratings_on_recipe_id"
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "recipe_generations", force: :cascade do |t|
    t.boolean "auto_publish_recipe", default: false, null: false
    t.text "avoid_ingredients"
    t.datetime "created_at", null: false
    t.text "customization_notes"
    t.text "data"
    t.string "dietary_preference"
    t.text "ingredient_swaps"
    t.text "prompt"
    t.datetime "published_at"
    t.integer "published_recipe_id"
    t.text "seed_publish_error"
    t.boolean "seed_tool", default: false, null: false
    t.integer "servings", default: 4, null: false
    t.string "skill_level"
    t.integer "target_difficulty"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["published_recipe_id"], name: "index_recipe_generations_on_published_recipe_id"
    t.index ["user_id"], name: "index_recipe_generations_on_user_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "notes"
    t.integer "position", default: 1, null: false
    t.string "quantity"
    t.text "raw", null: false
    t.integer "recipe_id", null: false
    t.string "unit"
    t.datetime "updated_at", null: false
    t.index ["recipe_id", "position"], name: "index_recipe_ingredients_on_recipe_id_and_position"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.integer "author_id"
    t.text "blurb"
    t.integer "category_id", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.integer "difficulty", default: 0
    t.integer "moderation_status", default: 0, null: false
    t.integer "nutrition_calories"
    t.decimal "nutrition_carbs_grams", precision: 8, scale: 2
    t.datetime "nutrition_computed_at"
    t.decimal "nutrition_fat_grams", precision: 8, scale: 2
    t.integer "nutrition_match_count", default: 0, null: false
    t.integer "nutrition_missing_ingredients_count", default: 0, null: false
    t.decimal "nutrition_protein_grams", precision: 8, scale: 2
    t.integer "prep_time", default: 0
    t.text "rejection_reason"
    t.datetime "reviewed_at"
    t.integer "reviewed_by_id"
    t.integer "servings", default: 4, null: false
    t.string "slug"
    t.string "tag_names"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_recipes_on_author_id"
    t.index ["category_id"], name: "index_recipes_on_category_id"
    t.index ["moderation_status"], name: "index_recipes_on_moderation_status"
    t.index ["reviewed_by_id"], name: "index_recipes_on_reviewed_by_id"
    t.index ["slug"], name: "index_recipes_on_slug", unique: true
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", limit: 1024, null: false
    t.integer "channel_hash", limit: 8, null: false
    t.datetime "created_at", null: false
    t.binary "payload", limit: 536870912, null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.text "payload"
    t.string "plan", null: false
    t.string "status", default: "pending", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_customer_id"
    t.string "stripe_price_id"
    t.string "stripe_subscription_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["plan"], name: "index_subscriptions_on_plan"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_checkout_session_id"], name: "index_subscriptions_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "taggings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable"
  end

  create_table "tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
  end

  create_table "user_follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "followed_id", null: false
    t.integer "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followed_id"], name: "index_user_follows_on_followed_id"
    t.index ["follower_id", "followed_id"], name: "index_user_follows_on_follower_id_and_followed_id", unique: true
    t.index ["follower_id"], name: "index_user_follows_on_follower_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin"
    t.string "api_key"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "free_generation_used_at"
    t.integer "generation_credits_balance", default: 0, null: false
    t.integer "generations_count", default: 0, null: false
    t.datetime "generations_reset_at"
    t.string "name"
    t.string "password_digest"
    t.string "plan", default: "free", null: false
    t.datetime "plan_expires_at"
    t.string "provider"
    t.string "recovery_digest"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["plan"], name: "index_users_on_plan"
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_users_on_stripe_subscription_id"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analytics_events", "users"
  add_foreign_key "chat_conversations", "users"
  add_foreign_key "chat_messages", "chat_conversations", column: "conversation_id"
  add_foreign_key "collection_recipes", "collections"
  add_foreign_key "collection_recipes", "recipes"
  add_foreign_key "collections", "users"
  add_foreign_key "credit_purchases", "users"
  add_foreign_key "favorites", "recipes"
  add_foreign_key "favorites", "users"
  add_foreign_key "grocery_list_items", "grocery_lists"
  add_foreign_key "grocery_lists", "meal_plans"
  add_foreign_key "grocery_lists", "users"
  add_foreign_key "meal_plans", "users"
  add_foreign_key "planned_meals", "meal_plans"
  add_foreign_key "planned_meals", "recipes"
  add_foreign_key "pro_waitlist_entries", "users"
  add_foreign_key "ratings", "recipes"
  add_foreign_key "ratings", "users"
  add_foreign_key "recipe_generations", "recipes", column: "published_recipe_id"
  add_foreign_key "recipe_generations", "users"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipes", "categories"
  add_foreign_key "recipes", "users", column: "author_id"
  add_foreign_key "recipes", "users", column: "reviewed_by_id"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "taggings", "tags"
  add_foreign_key "user_follows", "users", column: "followed_id"
  add_foreign_key "user_follows", "users", column: "follower_id"
end
