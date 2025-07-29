Rails.application.routes.draw do
  # Ruta principal - la app de una sola página
  root 'app#index'
  
  # Rutas para el flujo principal de VibeVoyage
  get '/app', to: 'app#index'
  
  scope '/app' do
    get '/', to: 'app#index', as: 'app_index'
    post '/create_real_journey', to: 'app#create_real_journey', as: 'app_create_real_journey'
    get '/status/:process_id', to: 'app#real_status', as: 'app_real_status'
  end
  # Rutas para explicaciones culturales
  post '/app/explain_choice', to: 'app#explain_choice', as: :app_explain_choice
  
  namespace :admin do
    get 'analytics/dashboard', to: 'analytics#dashboard'
    get 'analytics/health', to: 'analytics#health'
    get 'analytics/languages', to: 'analytics#languages'
  end

  # Rutas de itinerarios (para funcionalidad adicional)
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
  
  # Rutas de testing y desarrollo
  get '/app/test_apis', to: 'app#test_apis', as: :app_test_apis if Rails.env.development?
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
