# app/controllers/itineraries_controller.rb
class ItinerariesController < ApplicationController
  # skip_before_action :authenticate_user!, only: [:show]
  
  def new
    # Renderiza la interfaz principal (tu diseño elegante)
  end

  def create
    user_vibe = params[:user_vibe]

    if user_vibe.blank?
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace("magic_canvas", 
            partial: "itineraries/error_state", 
            locals: { error_message: "Por favor, describe tu vibe para poder crear una aventura." })
        end
        format.html { redirect_to new_itinerary_path, alert: "Por favor, describe tu vibe." }
        format.json { render json: { error: 'Vibe description is required' }, status: :bad_request }
      end
      return
    end

    # Generar process_id único basado en session
    process_id = "#{session.id}_#{SecureRandom.hex(8)}"
    
    # Estado inicial en cache para polling de respaldo
    initial_status = { 
      status: 'queued', 
      message: 'Iniciando análisis cultural...', 
      progress: 5 
    }
    Rails.cache.write("journey_#{process_id}", initial_status, expires_in: 15.minutes)

    # *** USAR EL JOB INTELIGENTE ***
    ProcessVibeJob.perform_later(process_id, user_vibe)

    # Mostrar estado inicial inmediatamente
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace("magic_canvas", 
          partial: "itineraries/live_processing_state", 
          locals: { 
            progress: 10,
            message: "Iniciando análisis cultural...",
            user_vibe: user_vibe,
            city_data: nil
          })
      end
      format.html do
        # Para navegadores sin JS, redirigir a página de status
        redirect_to "/itineraries/status/#{process_id}?user_vibe=#{CGI.escape(user_vibe)}"
      end
      format.json { render json: { process_id: process_id, status: 'queued' } }
    end
  end

  def show
    @itinerary = Itinerary.find(params[:id])
    @user_vibe = @itinerary.description
    @experiences = format_experiences_for_display(@itinerary)
    @city_data = { city: @itinerary.city }
  end

  def status
    process_id = params[:process_id] || params[:id]
    
    if request.format.html?
      # Página de status para fallback sin JS
      render :status
    else
      # API JSON para polling
      current_status = Rails.cache.read("journey_#{process_id}")
      
      if current_status
        render json: current_status
      else
        render json: { 
          status: 'expired', 
          message: 'Este proceso ha expirado o no se encontró.' 
        }, status: :not_found
      end
    end
  end

  # Test endpoint mejorado
  def test_apis
    interests = params[:interests] || ['tapas', 'cerveza']
    city = params[:city] || 'Madrid'

    puts "=== TESTING APIs COMPLETO ==="
    
    begin
      # Test completo del job
      test_process_id = "test_#{SecureRandom.hex(4)}"
      test_vibe = "#{interests.join(' y ')} en #{city}"
      
      puts "Ejecutando ProcessVibeJob en modo test..."
      
      # Ejecutar job de manera síncrona para testing
      job = ProcessVibeJob.new
      job.perform(test_process_id, test_vibe)
      
      render json: {
        status: 'test_completed',
        message: 'Job ejecutado exitosamente en modo test',
        test_vibe: test_vibe,
        process_id: test_process_id,
        check_logs: 'Revisa los logs del servidor para ver el flujo completo'
      }
      
    rescue => e
      render json: {
        status: 'test_failed',
        error: e.message,
        backtrace: e.backtrace.first(5)
      }, status: :internal_server_error
    end
  end

  private

  def format_experiences_for_display(itinerary)
    # Convertir stops a formato de experiencias
    itinerary.itinerary_stops.order(:position).map.with_index do |stop, index|
      {
        time: ["09:00 AM", "02:00 PM", "07:00 PM"][index] || "#{10 + index}:00 AM",
        title: stop.name || "Experiencia #{index + 1}",
        description: stop.description || "Una experiencia única",
        location: stop.name,
        area: extract_area_from_address(stop.address),
        duration: "2-3 hours",
        vibe_match: 85 + rand(10),
        image: get_default_image(index)
      }
    end
  end

  def extract_area_from_address(address)
    return "Centro" unless address
    
    # Extraer área de la dirección
    areas = ["Malasaña", "Centro", "La Latina", "Chueca", "Retiro", "Salamanca"]
    areas.find { |area| address.include?(area) } || "Centro"
  end

  def get_default_image(index)
    [
      "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&ixlib=rb-4.0.3",
      "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&auto=format&fit=crop&ixlib=rb-4.0.3", 
      "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
    ][index] || "https://images.unsplash.com/photo-1551632811-561732d1e306?w=800&auto=format&fit=crop&ixlib=rb-4.0.3"
  end
end