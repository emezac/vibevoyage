# config/routes.rb
Rails.application.routes.draw do
  require 'sidekiq/web'

  authenticate :user, lambda { |u| u.admin? } do
   mount Sidekiq::Web => '/sidekiq'
  end

  # Devise routes
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    passwords: 'users/passwords'
  }

  # Ruta principal - landing page para usuarios no autenticados
  root 'home#index'
  
  # Rutas protegidas para el flujo principal de VibeVoyage
  scope '/app' do
    get '/', to: 'app#index', as: 'app_index'
    post '/create_real_journey', to: 'app#create_real_journey', as: 'app_create_real_journey'
    get '/status/:process_id', to: 'app#real_status', as: 'app_real_status'
    post '/explain_choice', to: 'app#explain_choice', as: :app_explain_choice
  end

  # Rutas de subscripciones
  resources :subscriptions, only: [:index, :show, :create, :update] do
    member do
      post :subscribe
      delete :cancel
    end
  end

  # Rutas de perfil de usuario
  resource :profile, only: [:show, :edit, :update]

  # Rutas de admin
  namespace :admin do
    get 'analytics/dashboard', to: 'analytics#dashboard'
    get 'analytics/health', to: 'analytics#health'
    get 'analytics/languages', to: 'analytics#languages'
    resources :users, only: [:index, :show, :edit, :update]
    resources :subscription_plans
  end

  # Rutas de itinerarios (protegidas)
  resources :itineraries do
    member do
      get :status
    end
    
    resources :itinerary_stops do
      member do
        post :explain
      end
    end
  end

  # Rutas de itinerarios compartibles (ANTES de las rutas normales de itinerarios)
  get '/s/:slug', to: 'shared_itineraries#show', as: :shared_itinerary
  get '/s/:slug/image', to: 'shared_itineraries#generate_image', as: :shared_itinerary_image
  
  # Rutas para compartir
  resources :itineraries do
    member do
      post :make_public
      post :increment_share
      get :share_preview
      get :status
    end
    
    resources :itinerary_stops do
      member do
        post :explain
      end
    end
  end

  # Página de itinerarios públicos
  get '/discover', to: 'shared_itineraries#index', as: :discover_itineraries
  
  # Rutas de testing y desarrollo
  get '/app/test_apis', to: 'app#test_apis', as: :app_test_apis if Rails.env.development?
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
