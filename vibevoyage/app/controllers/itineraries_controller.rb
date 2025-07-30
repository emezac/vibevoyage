# app/controllers/itineraries_controller.rb
class ItinerariesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_itinerary, only: [:show, :edit, :update, :destroy, :make_public, :increment_share, :share_preview]

  def index
    @itineraries = current_user.itineraries.order(created_at: :desc)
  end

  def show
    @user_vibe = @itinerary.description
    @experiences = format_experiences_for_display(@itinerary)
    @city_data = { city: @itinerary.city }
  end

  def new
    @itinerary = current_user.itineraries.build
  end

  def create
    @itinerary = current_user.itineraries.build(itinerary_params)
    
    if @itinerary.save
      redirect_to @itinerary, notice: 'Itinerary was successfully created.'
    else
      render :new
    end
  end

  def edit
    # Vista para editar itinerario
  end

  def update
    if @itinerary.update(itinerary_params)
      redirect_to @itinerary, notice: 'Itinerary was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @itinerary.destroy
    redirect_to itineraries_path, notice: 'Itinerary was successfully deleted.'
  end

  def status
    process_id = params[:process_id] || params[:id]
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

  def make_public
    begin
      if @itinerary.make_public!
        render json: {
          success: true,
          share_url: shared_itinerary_url(@itinerary.slug),
          message: 'Your adventure is now public and ready to share!'
        }
      else
        render json: {
          success: false,
          message: 'Unable to make itinerary public'
        }
      end
    rescue => e
      Rails.logger.error "Error making itinerary public: #{e.message}"
      render json: {
        success: false,
        message: 'An error occurred while making your adventure public'
      }, status: :internal_server_error
    end
  end

  def increment_share
    begin
      @itinerary.increment_share_count!
      render json: { success: true }
    rescue => e
      Rails.logger.error "Error incrementing share count: #{e.message}"
      render json: { success: false }, status: :internal_server_error
    end
  end

  def share_preview
    @experiences = format_experiences_for_display(@itinerary)
    render layout: false
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

  def set_itinerary
    @itinerary = if params[:id].match?(/\A\d+\z/)
                   # Si es un número, buscar por ID
                   current_user.itineraries.find(params[:id])
                 else
                   # Si no es un número, buscar por slug
                   current_user.itineraries.find_by!(slug: params[:id])
                 end
  rescue ActiveRecord::RecordNotFound
    redirect_to itineraries_path, alert: 'Itinerary not found.'
  end

  def itinerary_params
    params.require(:itinerary).permit(:name, :description, :city, :location)
  end

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