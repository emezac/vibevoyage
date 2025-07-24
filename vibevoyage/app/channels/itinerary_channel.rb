# app/channels/itinerary_channel.rb
class ItineraryChannel < ApplicationCable::Channel
  def subscribed
    stream_from "itinerary_channel:#{params[:session_id]}"
    puts "=== Usuario suscrito al canal: itinerary_channel:#{params[:session_id]} ==="
  end

  def unsubscribed
    puts "=== Usuario desconectado del canal ==="
  end
end
