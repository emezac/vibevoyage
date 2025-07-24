Rails.application.routes.draw do
  # Ruta principal - la app de una sola página
  root 'app#index'
  
  # Rutas para el flujo principal de VibeVoyage
  get '/app', to: 'app#index'
  post '/app/create_real_journey', to: 'app#create_real_journey', as: :app_create_real_journey
  get '/app/real_status/:process_id', to: 'app#real_status', as: :app_real_status
  
  # Rutas para explicaciones culturales
  post '/app/explain_choice', to: 'app#explain_choice', as: :app_explain_choice
  
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