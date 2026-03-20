Rails.application.routes.draw do
  root to: "home#index"

  namespace :api, defaults: { format: :json } do
    resources :recipes, param: :slug, only: %i[create update]
  end

  resource :pricing, only: :show, controller: :pricing

  resource :chat, only: [:show], controller: :chat do
    post :create_message
    post :create_conversation
  end
  get "chat/:conversation_id", to: "chat#show", as: :chat_conversation
  patch "chat/:conversation_id", to: "chat#update_conversation", as: :update_chat_conversation
  delete "chat/:conversation_id", to: "chat#destroy_conversation", as: :destroy_chat_conversation
  resources :pro_waitlist_entries, only: :create

  namespace :profiles do
    resource :meal_plan, only: :show
    resources :collections
    resources :collection_recipes, only: %i[create destroy]
    resources :favorites, only: %i[index]
    resources :grocery_list_items, only: :update
    resources :grocery_lists, only: %i[create show]
    resources :planned_meals, only: %i[create update destroy] do
      member do
        post :duplicate
      end
    end
    resources :recipes, only: %i[index]
  end

  namespace :billing do
    resources :checkout_sessions, only: :create
    post "webhooks/stripe", to: "webhooks#stripe"
  end

  resources :families do
    resources :memberships, controller: "families/memberships", only: %i[create update destroy]
    resources :cookbooks, controller: "families/cookbooks", only: %i[show create edit update destroy] do
      resources :recipes, controller: "families/cookbook_recipes", as: :cookbook_recipes, only: %i[create destroy]
    end
  end

  resources :cooks, only: :show, param: :username do
    resource :follow, only: %i[create destroy], controller: "cooks/follows"
  end

  namespace :admin do
    resources :recipe_submissions, only: :index do
      member do
        patch :approve
        patch :reject
      end
    end

    resources :seed_recipes, only: %i[index show create] do
      member do
        post :publish
      end
    end

    resources :seed_categories, only: %i[index show] do
      member do
        post :publish
      end
    end
  end

  resources :profiles, only: %i[show edit update]

  namespace :recipes do
    get "favorites/create"
    resources :generations do
      member do
        post :regenerate_recipe
        post :regenerate_instructions
        post :regenerate_images
      end
    end
  end

  resources :pages, only: [] do
    collection do
      get :privacy
      get :terms
      get :about
    end
  end

  get "/about", to: redirect("/pages/about")

  resources :sessions, only: %i[new create destroy]
  resources :password_resets, param: :token, only: %i[new create edit update]
  resources :grocery_lists, only: :show, param: :share_token
  resources :auth, only: [] do
    collection do
      get "/:provider/callback" => "auth#callback"
    end
  end

  resources :recipes, param: :slug do
    member do
      get :cook
      get :print
    end

    resources :ratings, controller: "recipes/ratings"
    resources :favorites, controller: "recipes/favorites", only: %i[create destroy]
  end
  resources :categories, param: :slug
  resources :registrations, only: %i[new create]

  mount MissionControl::Jobs::Engine, at: "/jobs"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
