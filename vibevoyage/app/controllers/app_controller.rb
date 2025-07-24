# app/controllers/app_controller.rb
class AppController < ApplicationController
  def index
    # Renderiza la interfaz principal (tu diseño de una sola página)
  end

  def create_real_journey
    user_vibe = params[:user_vibe]

    if user_vibe.blank?
      render json: { error: 'Vibe description is required' }, status: :bad_request
      return
    end

    # Generar process_id único
    process_id = "#{session.id}_#{SecureRandom.hex(8)}"
    
    # Estado inicial en cache
    initial_status = { 
      status: 'queued', 
      message: 'Iniciando análisis cultural...', 
      progress: 5 
    }
    Rails.cache.write("journey_#{process_id}", initial_status, expires_in: 15.minutes)

    # *** USAR EL JOB INTELIGENTE MEJORADO CON APIs REALES ***
    ProcessVibeJobIntelligent.perform_later(process_id, user_vibe)

    render json: { process_id: process_id, status: 'queued' }
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