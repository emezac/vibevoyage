# Herramienta personalizada para consumir la API de Google Places
require 'httpx'

class MapsApiTool
  API_KEY = ENV['GOOGLE_PLACES_API_KEY']
  API_SERVER = 'https://maps.googleapis.com/maps/api/place'

  # Ejemplo de método para buscar lugares
  def self.search_places(params = {})
    response = HTTPX.with(headers: {
      'Content-Type' => 'application/json'
    }).get("#{API_SERVER}/textsearch/json", params: params.merge(key: API_KEY))

    if response.status == 200
      JSON.parse(response.body.to_s)
    else
      { error: response.status, body: response.body.to_s }
    end
  rescue => e
    { error: 'exception', message: e.message }
  end
end
