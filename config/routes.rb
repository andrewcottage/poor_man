Rails.application.routes.draw do
  namespace :recipes do
    get "favorites/create"
  end
  resources :pages, only: [] do
    collection do
      get :privacy
      get :terms
    end
  end

  root to: "home#index"

  get "about" => "home#about"
  
  resources :featured, only: %i[index]
  resources :sessions, only: %i[new create destroy]
  resources :auth, only: [] do
    collection do 
      get "/:provider/callback" => "auth#callback"
    end
  end
  resources :recipes, param: :slug do 
    resources :ratings, controller: "recipes/ratings"
    resources :favorites, controller: "recipes/favorites", only: %i[create destroy]
  end
  resources :categories, param: :slug
  resources :registrations, only: %i[new create]
  
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
