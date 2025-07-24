
class ItineraryStopsController < ApplicationController
  before_action :set_itinerary
  before_action :set_itinerary_stop, only: [:show, :update, :destroy]

  def index
    @itinerary_stops = @itinerary.itinerary_stops
    render json: @itinerary_stops
  end

  def show
    render json: @itinerary_stop
  end

  def create
    @itinerary_stop = @itinerary.itinerary_stops.new(itinerary_stop_params)
    if @itinerary_stop.save
      render json: @itinerary_stop, status: :created
    else
      render json: @itinerary_stop.errors, status: :unprocessable_entity
    end
  end

  def update
    if @itinerary_stop.update(itinerary_stop_params)
      render json: @itinerary_stop
    else
      render json: @itinerary_stop.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @itinerary_stop.destroy
    head :no_content
  end

  def explain
    # Recuperamos el vibe original que pasamos como parámetro desde el botón.
    user_vibe = params[:user_vibe]

    # Encolamos un job específico para generar solo la explicación.
    # Es crucial pasar el session.id para saber a qué navegador enviarle la respuesta.
    ExplanationGenerationJob.perform_later(
      itinerary_stop_id: @itinerary_stop.id,
      user_vibe: user_vibe,
      session_id: session.id.to_s # Convertimos a string para que sea serializable.
    )

    # Inmediatamente después de encolar el job, respondemos al navegador.
    # Esta respuesta reemplazará el contenido del turbo_frame_tag 'details'
    # con un mensaje de "pensando".
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          dom_id(@itinerary_stop, :details),
          partial: 'itineraries/thinking_explanation'
        )
      end
    end
  end

  private
    def set_itinerary
      @itinerary = Itinerary.find(params[:itinerary_id])
    end

    def set_itinerary_stop
      @itinerary_stop = @itinerary.itinerary_stops.find(params[:id])
    end

    def itinerary_stop_params
      params.require(:itinerary_stop).permit(:name, :description, :latitude, :longitude)
    end
end
