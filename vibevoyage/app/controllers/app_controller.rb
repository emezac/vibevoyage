# app/controllers/app_controller.rb
class AppController < ApplicationController
  before_action :authenticate_user!
  before_action :check_subscription_limits, only: [:create_real_journey]

  def index
    @current_user = current_user
    @subscription_plan = current_user.subscription_plan || SubscriptionPlan.free_plan
    @journeys_remaining = current_user.journeys_remaining_this_month
    @can_create_journey = current_user.can_create_journey?
    
    # Si no puede crear más journeys, mostrar mensaje
    unless @can_create_journey
      @upgrade_needed = true
    end
  end

  def create_real_journey
    user_vibe = params[:user_vibe]
    puts "=== EJECUTANDO PROCESAMIENTO INTELIGENTE SÍNCRONAMENTE ==="
    puts "User vibe: #{user_vibe}"
    
    begin
      # Verificar que puede crear más journeys
      unless current_user.can_create_journey?
        return render json: {
          success: false,
          error: 'subscription_limit_reached',
          message: 'You have reached your monthly journey limit. Please upgrade your subscription to continue.',
          upgrade_url: subscriptions_path
        }
      end

      # Crear un process_id temporal para la ejecución síncrona
      temp_process_id = "sync_#{SecureRandom.hex(8)}"
      
      # ✅ INICIALIZAR el estado en cache ANTES de ejecutar el job
      Rails.cache.write("journey_#{temp_process_id}", {
        status: 'processing',
        progress: 0,
        message: 'Iniciando análisis cultural...'
      }, expires_in: 30.minutes)
      
      # ✅ INCREMENTAR contador de journeys
      current_user.increment_journey_count!
      
      # ✅ DEVOLVER inmediatamente el process_id para que el frontend inicie el polling
      render json: {
        success: true,
        process_id: temp_process_id
      }
      
      # ✅ EJECUTAR el job en background para no bloquear la respuesta
      ProcessVibeJobIntelligent.perform_later(temp_process_id, user_vibe)
      
    rescue => e
      puts "❌ Error iniciando ProcessVibeJobIntelligent: #{e.message}"
      Rails.logger.error "Error: #{e.message}\n#{e.backtrace.join("\n")}"
      
      render json: {
        success: false,
        error: e.message,
        message: "Error procesando tu vibe: #{e.message}. Puedes intentar de nuevo."
      }
    end
  end

def real_status
  process_id = params[:process_id]
  puts "=== REAL_STATUS called for: #{process_id} ==="
  
  status_data = Rails.cache.read("journey_#{process_id}")
  puts "=== Status data from cache: #{status_data.inspect} ==="
  
  if status_data
    # ✅ MEJORADO: Asegurar que el itinerary_id esté disponible en la respuesta
    if status_data[:status] == 'complete' && status_data[:itinerary]
      # Si hay itinerary_id en el cache, incluirlo en la respuesta del itinerary
      if status_data[:itinerary_id]
        status_data[:itinerary][:id] = status_data[:itinerary_id]
        puts "=== Added itinerary_id to response: #{status_data[:itinerary_id]} ==="
      end
      
      # También incluir el itinerary_id directamente para compatibilidad
      status_data[:itinerary_id] = status_data[:itinerary_id] if status_data[:itinerary_id]
    end
    
    puts "=== Returning status: #{status_data[:status]} ==="
    render json: status_data
  else
    puts "=== No status data found for process_id: #{process_id} ==="
    render json: { 
      status: 'not_found', 
      message: 'Proceso no encontrado', 
      progress: 0 
    }
  end
rescue => e
  puts "=== ERROR in real_status: #{e.message} ==="
  Rails.logger.error "Error en real_status: #{e.message}"
  render json: { 
    status: 'error', 
    message: 'Error del servidor', 
    progress: 0 
  }
end

  # Endpoint para explicaciones del "¿Por qué?"
  def explain_choice
    stop_id = params[:stop_id]
    
    # Buscar el stop y su razón cultural
    stop = ItineraryStop.find(stop_id)
    
    if stop.cultural_explanation.present?
      render json: { 
        explanation: stop.cultural_explanation,
        cached: true
      }
    else
      # Generar explicación usando LLM si no existe
      ExplainChoiceJob.perform_later(stop_id)
      render json: { 
        status: 'generating',
        message: 'Generando explicación cultural...'
      }
    end
  end

  private

  def check_subscription_limits
    unless current_user.can_create_journey?
      redirect_to subscriptions_path, alert: 'You have reached your monthly journey limit. Please upgrade your subscription to continue creating cultural adventures.'
    end
  end
end