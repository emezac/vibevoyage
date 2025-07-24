# app/workflow_handlers/turbo_stream_handler.rb
module WorkflowHandlers
  class TurboStreamHandler
    def self.call(input_data, workflow_variables)
      puts "=== TurboStreamHandler ejecutándose ==="
      puts "Input data: #{input_data.inspect}"
      
      session_id = input_data[:session_id] || input_data['session_id']
      itinerary = input_data[:itinerary] || input_data['itinerary']
      user_vibe = input_data[:user_vibe] || input_data['user_vibe']
      
      begin
        Turbo::StreamsChannel.broadcast_replace_to(
          "itinerary_channel:#{session_id}",
          target: "magic_canvas",
          partial: "itineraries/results",
          locals: { 
            itinerary: itinerary,
            user_vibe: user_vibe 
          }
        )
        
        puts "✅ TurboStream enviado exitosamente"
        
        { 
          success: true, 
          session_id: session_id,
          broadcast_sent: true
        }
      rescue => e
        puts "❌ Error enviando TurboStream: #{e.message}"
        
        { 
          success: false, 
          error: e.message 
        }
      end
    end
  end
end
