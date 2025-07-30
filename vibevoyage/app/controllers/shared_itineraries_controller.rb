# app/controllers/shared_itineraries_controller.rb
class SharedItinerariesController < ApplicationController
  # NO require authentication for public sharing - allow public access
  before_action :find_itinerary, only: [:show, :generate_image]

  layout 'shared'

  def index
    @featured_itineraries = Itinerary.public_itineraries
                                    .includes(:user, :itinerary_stops)
                                    .popular
                                    .limit(6)
    
    @recent_itineraries = Itinerary.public_itineraries
                                  .includes(:user, :itinerary_stops)
                                  .recent_shared
                                  .limit(12)
  end

  def show
    # Track view for analytics
    @itinerary.increment_view_count! unless owner_viewing?
    
    @user = @itinerary.user
    @experiences = format_experiences_for_display(@itinerary)
    @is_owner = owner_viewing?
    
    # Store meta data for the view to use
    @page_title = @itinerary.shareable_title
    @page_description = @itinerary.shareable_description
    @page_image = @itinerary.og_image_url || shared_itinerary_image_url(@itinerary)
  end

  def generate_image
    # Generate dynamic OG image
    @experiences = format_experiences_for_display(@itinerary)
    
    respond_to do |format|
      format.html { render layout: false }
      format.png do
        # Use a service to generate image (we'll implement this)
        render plain: "Image generation coming soon"
      end
    end
  end

  private

  def find_itinerary
    @itinerary = Itinerary.public_itineraries.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'This itinerary is not available for sharing.'
  end

  def owner_viewing?
    user_signed_in? && current_user == @itinerary.user
  end

  def format_experiences_for_display(itinerary)
    itinerary.itinerary_stops.order(:position).map.with_index do |stop, index|
      {
        time: ["09:00 AM", "02:00 PM", "07:00 PM"][index] || "#{10 + index}:00 AM",
        title: stop.name || "Experience #{index + 1}",
        description: stop.description || "A unique cultural experience",
        location: stop.name,
        area: extract_area_from_address(stop.address),
        duration: "2-3 hours",
        vibe_match: 85 + rand(10),
        image: get_default_image(index),
        cultural_explanation: stop.cultural_explanation.presence || "This unique spot was chosen to perfectly align with the journey's cultural vibe, offering an authentic and memorable experience.",
        why_chosen: stop.why_chosen.presence
      }
    end
  end

  def extract_area_from_address(address)
    return "Centro" unless address
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