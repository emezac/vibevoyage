# app/workflows/handlers/save_itinerary_handler.rb
module WorkflowHandlers
  class SaveItineraryHandler
    def self.call(input_data, workflow_variables)
      puts "=== SaveItineraryHandler ejecutándose ==="
      puts "Input data: #{input_data.inspect}"

      begin
        # Crear el itinerario en la base de datos
        itinerary = Itinerary.create!(
          user_id: input_data[:user_id],
          description: input_data[:user_vibe],
          city: input_data[:city],
          narrative_html: input_data[:narrative_html]
        )
        
        puts "=== Itinerario creado con ID: #{itinerary.id} ==="
        
        # Si hay stops, crearlos también
        if input_data[:curated_stops].present?
          stops_data = JSON.parse(input_data[:curated_stops]) rescue []
          
          stops_data.each_with_index do |stop_data, index|
            itinerary.itinerary_stops.create!(
              name: stop_data['name'],
              description: stop_data['description'],
              address: stop_data['address'],
              position: index + 1
            )
          end
          
          puts "=== Creados #{stops_data.size} stops ==="
        end
        
        result = {
          itinerary: itinerary,
          success: true
        }
        
        puts "=== SaveItineraryHandler resultado ==="
        puts "Itinerary ID: #{itinerary.id}"
        puts "Stops count: #{itinerary.itinerary_stops.count}"
        
        { handler_result: result }
        
      rescue => e
        puts "=== ERROR en SaveItineraryHandler ==="
        puts "Error: #{e.message}"
        puts "Backtrace: #{e.backtrace.first(5)}"
        
        { handler_result: { success: false, error: e.message } }
      end
    end

      # 1. Recuperar los datos de los pasos anteriores del workflow.
      user_id = workflow_variables.dig(:initial_input, :user_id)
      user_vibe = workflow_variables.dig(:initial_input, :user_vibe)
      curated_stops = workflow_variables.dig(:curate_stops, :output_data, :llm_response) # Adapta esta ruta
      narrative_html = workflow_variables.dig(:build_narrative, :output_data, :narrative_html) # Adapta esta ruta
      city = workflow_variables.dig(:parse_vibe, :output_data, :llm_response, :city) # Adapta esta ruta
      user = User.find_by(id: user_id) # Puede ser nil si no hay usuarios

      # --- LOGS DE DIAGNÓSTICO ---
      puts "Datos recibidos por SaveItineraryHandler:"
      puts "  - User ID: #{user_id}"
      puts "  - City: #{city}"
      puts "  - Stops count: #{curated_stops&.count}"
      # --- FIN DE LOGS ---

      # 2. Crear el itinerario. Asócialo al usuario si existe.
      itinerary_attributes = {
        name: "Tu Aventura en #{city}",
        location: city,
        narrative_html: narrative_html,
        description: user_vibe # Guardamos el vibe original aquí
      }
      itinerary_attributes[:user_id] = user.id if user

      itinerary = Itinerary.create!(itinerary_attributes)

      # 3. Crear las paradas del itinerario, guardando el contexto de Qloo.
      curated_stops.each do |stop_data|
        itinerary.itinerary_stops.create!(
          name: stop_data['name'],
          description: stop_data['description'],
          address: stop_data['address'],
          qloo_data: stop_data['qloo_data_original'] # Asegúrate de que esta data se pase
        )
      end

            
      puts "--- [SaveItineraryHandler] Itinerario guardado con ID: #{itinerary.id} ---"

      # 4. Devolver el objeto Itinerary para la tarea final.
      { success: true, itinerary: itinerary.reload }
    rescue => e
      puts "--- [SaveItineraryHandler] ERROR: #{e.message} ---"
      Rails.logger.error "SaveItineraryHandler falló: #{e.message}"
      { success: false, error: e.message }
    end
  end
end