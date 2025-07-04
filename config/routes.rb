Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by uptime monitors like upstack.com/uptime-monitoring
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  root "home#index"

  get "/about", to: "pages#about"
  get "/privacy", to: "pages#privacy"
  get "/terms", to: "pages#terms"

  resources :categories, param: :slug do
    collection do
      get :suggest
    end
  end

  resources :recipes, param: :slug do
    collection do
      post :generate_with_ai
    end
    
    resources :ratings, except: [:index, :show]
    resources :favorites, only: [:create, :destroy]
  end

  resources :profiles, only: [:show, :edit, :update] do
    resources :recipes, only: [:index], module: :profiles
    resources :favorites, only: [:index], module: :profiles
  end

  resources :registrations, only: [:new, :create]
  resources :sessions, only: [:new, :create, :destroy]

  get "/auth/:provider/callback", to: "auth#omniauth"
end
