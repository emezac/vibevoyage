# app/controllers/app_controller.rb
class AppController < ApplicationController
  def index
    # Renderiza la interfaz principal (tu diseño de una sola página)
  end

# En app/controllers/app_controller.rb

def create_real_journey
  user_vibe = params[:user_vibe]
  puts "=== EJECUTANDO PROCESAMIENTO INTELIGENTE SÍNCRONAMENTE ==="
  puts "User vibe: #{user_vibe}"
  
  begin
    # Crear un process_id temporal para la ejecución síncrona
    temp_process_id = "sync_#{SecureRandom.hex(8)}"
    
    # ✅ INICIALIZAR el estado en cache ANTES de ejecutar el job
    Rails.cache.write("journey_#{temp_process_id}", {
      status: 'processing',
      progress: 0,
      message: 'Iniciando análisis cultural...'
    }, expires_in: 30.minutes)
    
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

  # def real_status
  #   process_id = params[:process_id]
  #   current_status = Rails.cache.read("journey_#{process_id}")
    
  #   if current_status
  #     render json: current_status
  #   else
  #     render json: { 
  #       status: 'expired', 
  #       message: 'Este proceso ha expirado o no se encontró.' 
  #     }, status: :not_found
  #   end
  # end
  # En app/controllers/app_controller.rb

def real_status
  process_id = params[:process_id]
  puts "=== REAL_STATUS called for: #{process_id} ==="
  
  status_data = Rails.cache.read("journey_#{process_id}")
  puts "=== Status data from cache: #{status_data.inspect} ==="
  
  if status_data
    # ✅ FIX: Asegurar que el status se devuelva correctamente
    puts "=== Returning status: #{status_data[:status]} ==="
    render json: status_data
  else
    # ✅ FIX: Si no hay datos en cache, devolver un estado de error
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
end