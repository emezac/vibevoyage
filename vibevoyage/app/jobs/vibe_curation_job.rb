# app/jobs/vibe_curation_job.rb

# Definir los handlers aquí mismo para evitar problemas de carga
module WorkflowHandlers
  class NarrativeBuilder
    def self.call(input_data, workflow_variables)
      puts "=== NarrativeBuilder ejecutándose ==="
      puts "Input data: #{input_data.inspect}"
      
      city = input_data[:city] || input_data['city'] || 'Unknown'
      original_vibe = input_data[:original_vibe] || input_data['original_vibe'] || ''
      
      narrative_html = <<~HTML
        <div class="narrative">
          <h2>Tu aventura en #{city}</h2>
          <p>Basado en tu vibe: "#{original_vibe}"</p>
          <div class="vibe-analysis">
            <p>Hemos creado una experiencia perfecta para ti en #{city}.</p>
          </div>
        </div>
      HTML
      
      result = {
        narrative: narrative_html,
        city: city,
        original_vibe: original_vibe,
        success: true
      }
      
      puts "=== NarrativeBuilder resultado: #{result.inspect}"
      result
    end
  end

  class SaveItineraryHandler
    def self.call(input_data, workflow_variables)
      puts "=== SaveItineraryHandler ejecutándose ==="
      puts "Input data: #{input_data.inspect}"
      
      begin
        # Crear el itinerario en la base de datos
        itinerary = Itinerary.create!(
          user_id: input_data[:user_id] || input_data['user_id'],
          description: input_data[:user_vibe] || input_data['user_vibe'],
          city: input_data[:city] || input_data['city'],
          narrative_html: input_data[:narrative_html] || input_data['narrative_html']
        )
        
        puts "=== Itinerario creado con ID: #{itinerary.id} ==="
        
        result = {
          itinerary: itinerary,
          success: true,
          itinerary_id: itinerary.id
        }
        
        puts "=== SaveItineraryHandler resultado: #{result.inspect}"
        result
        
      rescue => e
        puts "=== ERROR en SaveItineraryHandler: #{e.message} ==="
        puts "=== Backtrace: #{e.backtrace.first(3)}"
        { 
          success: false, 
          error: e.message 
        }
      end
    end
  end

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
        
        puts "✅ TurboStream enviado exitosamente a canal: itinerary_channel:#{session_id}"
        
        { 
          success: true, 
          session_id: session_id,
          broadcast_sent: true
        }
      rescue => e
        puts "❌ Error enviando TurboStream: #{e.message}"
        puts "❌ Backtrace: #{e.backtrace.first(3)}"
        
        { 
          success: false, 
          error: e.message 
        }
      end
    end
  end
end

# Definir el workflow aquí mismo también
module Workflows
  class VibeVoyageWorkflow
    def self.tasks
      {
        'parse_vibe' => {
          type: 'llm',
          name: 'Parse User Vibe',
          input_data: {
            prompt: "Analyze the following text and extract key cultural entities. Your goal is to generate clean, useful JSON for a recommendation API.
            Rules:
            1. CITY IDENTIFICATION - Look for ANY mention of cities, including direct mentions (\"Mexico City\", \"Paris\"), local references (\"CDMX\", \"NYC\"), or contextual clues (\"capital of France\"). If no location is mentioned, use \"New York\" as default. ALWAYS use the full, standardized city name in English (e.g., \"Mexico City\" not \"CDMX\").
            2. Extract ONLY specific place types or venue categories (e.g., 'art museum', 'coffee shop', 'cinema', 'tapas bar'). DO NOT include vague adjectives.
            3. Identify general experience themes (e.g., 'culture', 'gastronomy', 'nightlife').
            4. Respond ONLY with valid JSON, no markdown or extra text.
            User Text: '${initial_input.user_vibe}'
            Example for \"un dia tranquilo en Madrid con tapas y Cerveza\": { \"city\": \"Madrid\", \"interests\": [\"tapas bar\", \"cerveceria\"], \"preferences\": [\"gastronomy\", \"relax\"] }",
            model_params: { temperature: 0.7, max_tokens: 500 }
          },
          next_task_id_on_success: 'validate_city'
        },
        'validate_city' => {
          type: 'llm',
          name: 'Validate City Name',
          input_data: {
            prompt: "You are a city name validator. Standardize the city name to its most common English format.
            Common standardizations: \"CDMX\" -> \"Mexico City\", \"NYC\" -> \"New York\", \"Roma\" -> \"Rome\".
            Input JSON: ${parse_vibe.llm_response}
            Return the same JSON structure but with a corrected city name.",
            model_params: { temperature: 0.3, max_tokens: 200 }
          },
          next_task_id_on_success: 'build_narrative'
        },
        'build_narrative' => {
          type: 'direct_handler',
          name: 'Build Travel Narrative',
          handler: 'WorkflowHandlers::NarrativeBuilder#call',
          input_data: {
            city: '${validate_city.llm_response.city}',
            original_vibe: '${initial_input.user_vibe}',
            user_preferences: '${validate_city.llm_response.preferences}'
          },
          next_task_id_on_success: 'save_itinerary_to_db'
        },
        'save_itinerary_to_db' => {
          type: 'direct_handler',
          name: 'Save Itinerary to Database',
          handler: 'WorkflowHandlers::SaveItineraryHandler#call',
          input_data: {
            user_id: '${initial_input.user_id}',
            user_vibe: '${initial_input.user_vibe}',
            city: '${validate_city.llm_response.city}',
            narrative_html: '${build_narrative.narrative}'
          },
          next_task_id_on_success: 'finalize'
        },
        'finalize' => {
          type: 'direct_handler',
          name: 'Send Results to Frontend',
          handler: 'WorkflowHandlers::TurboStreamHandler#call',
          input_data: {
            session_id: '${initial_input.session_id}',
            itinerary: '${save_itinerary_to_db.itinerary}',
            user_vibe: '${initial_input.user_vibe}'
          },
          next_task_id_on_success: nil
        }
      }
    end
  end
end

class VibeCurationJob < ApplicationJob
  queue_as :default

  def perform(user_id, user_vibe, session_id)
    puts "=== INICIANDO VibeCurationJob ==="
    puts "user_vibe: #{user_vibe}"
    puts "session_id: #{session_id}"
    puts "WorkflowHandlers disponible: #{defined?(WorkflowHandlers)}"
    puts "Workflows disponible: #{defined?(Workflows)}"
    
    if defined?(WorkflowHandlers)
      puts "Handlers: #{WorkflowHandlers.constants}"
    end
    
    # Cargar la definición del workflow
    tasks_definition = Workflows::VibeVoyageWorkflow.tasks
    
    puts "=== TASKS DEFINITION ==="
    puts "Type: #{tasks_definition.class}"
    puts "Keys: #{tasks_definition.keys}"
    
    workflow_data = {
      workflow_id: "vibe_#{session_id}",
      name: "Vibe Voyage Curation",
      tasks: tasks_definition
    }
    
    puts "=== WORKFLOW DATA ==="
    puts "Workflow ID: #{workflow_data[:workflow_id]}"
    puts "Tasks count: #{workflow_data[:tasks].size}"
    
    # Verificar la primera tarea
    first_task = workflow_data[:tasks]['parse_vibe']
    puts "=== PRIMERA TAREA ==="
    if first_task
      puts "✅ parse_vibe encontrada"
      puts "Type: #{first_task[:type]}"
      puts "Name: #{first_task[:name]}"
      puts "Next task: #{first_task[:next_task_id_on_success]}"
    else
      puts "❌ parse_vibe NO encontrada"
    end

    llm_config = {
      api_key: Rdawn.config.llm_api_key,
      model: Rdawn.config.llm_model,
      provider: Rdawn.config.llm_provider.to_sym
    }
    
    puts "=== LLM CONFIG ==="
    puts "Provider: #{llm_config[:provider]}"
    puts "Model: #{llm_config[:model]}"
    puts "API Key present: #{llm_config[:api_key].present?}"
    
    initial_input = {
      user_id: user_id,
      user_vibe: user_vibe,
      session_id: session_id
    }

    puts "=== INITIAL INPUT ==="
    puts initial_input.inspect

    puts "=== EJECUTANDO WORKFLOW ==="
    
    # Ejecutar el workflow
    result = Rdawn::Rails::WorkflowJob.run_workflow_now(
      workflow_data: workflow_data,
      llm_config: llm_config,
      initial_input: initial_input
    )

    puts "=== RESULTADO DEL WORKFLOW ==="
    puts "Status: #{result.status}"
    puts "Variables keys: #{result.variables.keys}"
    
    # Mostrar todas las variables
    result.variables.each do |key, value|
      puts "Variable #{key}: #{value.class}"
      if value.respond_to?(:keys) && value.keys.size < 10
        puts "  Keys: #{value.keys}"
      elsif value.is_a?(String) && value.length < 200
        puts "  Value: #{value}"
      else
        puts "  Size: #{value.size}" if value.respond_to?(:size)
      end
    end

    # Verificar tareas específicas
    expected_tasks = ['parse_vibe', 'validate_city', 'build_narrative', 'save_itinerary_to_db', 'finalize']
    puts "=== VERIFICANDO TAREAS ESPERADAS ==="
    expected_tasks.each do |task_name|
      if result.variables[task_name.to_sym]
        puts "✅ #{task_name}: ENCONTRADA"
        task_result = result.variables[task_name.to_sym]
        if task_result.respond_to?(:keys)
          puts "   Keys: #{task_result.keys}"
        end
      else
        puts "❌ #{task_name}: NO ENCONTRADA"
      end
    end

    if result.status == :failed
      Rails.logger.error "VibeCurationJob falló"
      puts "=== WORKFLOW FALLÓ ==="
      
      # Enviar error al frontend
      Turbo::StreamsChannel.broadcast_replace_to(
        "itinerary_channel:#{session_id}",
        target: "magic_canvas",
        partial: "itineraries/error_state",
        locals: { error_message: "No pudimos generar tu itinerario. Por favor, intenta de nuevo." }
      )
    else
      Rails.logger.info "VibeCurationJob completado para session_id: #{session_id}"
      puts "=== WORKFLOW COMPLETADO EXITOSAMENTE ==="
      
      # Si hay un itinerario en las variables, enviarlo al frontend como fallback
      if result.variables[:save_itinerary_to_db]&.dig(:itinerary)
        puts "=== ENVIANDO FALLBACK AL FRONTEND ==="
        itinerary = result.variables[:save_itinerary_to_db][:itinerary]
        
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
          puts "✅ Fallback enviado exitosamente"
        rescue => e
          puts "❌ Error enviando fallback: #{e.message}"
        end
      end
    end
  end
end