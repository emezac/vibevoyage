# app/jobs/explanation_generation_job.rb
class ExplanationGenerationJob < ApplicationJob
  queue_as :default

  def perform(itinerary_stop_id:, user_vibe:, session_id:)
    # 1. Obtenemos los datos necesarios de la base de datos.
    stop = ItineraryStop.find(itinerary_stop_id)
    
    # Esto es por qué era tan importante guardar el contexto de Qloo.
    qloo_data = stop.qloo_data.deep_symbolize_keys
    qloo_keywords = qloo_data.dig(:properties, :keywords)&.join(', ') || "datos culturales"

    # 2. Creamos el prompt para el LLM.
    prompt = <<-PROMPT.strip_heredoc
      Eres un curador cultural experto y un narrador de viajes poético.
      El gusto inicial del usuario fue: "#{user_vibe}".
      Basado en eso, se recomendó el lugar: "#{stop.name}".
      Nuestra base de datos cultural (Qloo) asocia este lugar con las siguientes palabras clave: "#{qloo_keywords}".

      Tu tarea: Explica en un párrafo evocador y convincente (máximo 80 palabras) por qué "#{stop.name}" es la parada perfecta para este usuario. Conecta su vibe inicial con las palabras clave culturales. Si los datos lo mencionan, incluye un detalle histórico o único del lugar.

      Ejemplo de Tono: "Dado tu amor por el cine clásico, el Café Doré es más que una simple cafetería; es un portal a la historia del cine de Madrid. Su arquitectura Art Nouveau y su conexión con la Filmoteca Española lo convierten en el escenario perfecto para comenzar un día de inspiración cinematográfica."
    PROMPT

    # 3. Definimos un workflow de `rdawn` de una sola tarea.
    workflow = Rdawn::Workflow.new(workflow_id: "explain_#{stop.id}_#{Time.now.to_i}", name: "Explain Stop")
    
    task = Rdawn::Task.new(
      task_id: '1',
      name: 'Generate Explanation',
      is_llm_task: true,
      input_data: { prompt: prompt }
    )
    workflow.add_task(task)

    # 4. Ejecutamos el workflow de forma síncrona DENTRO del job.
    llm_interface = Rdawn::LLMInterface.new(
      provider: :openai, # Especifica explícitamente el proveedor
      api_key: ENV['OPENAI_API_KEY']
    )
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
    result = agent.run
    
    explanation_text = result.variables.dig('1', :output_data, :llm_response) || "No pude generar una explicación en este momento."

    # 5. Enviamos el resultado de vuelta a la UI usando Turbo Streams.
    #    El canal se identifica por el session_id que pasamos al job.
    Turbo::StreamsChannel.broadcast_update_to(
      "itinerary_channel:#{session_id}",
      target: ActionView::RecordIdentifier.dom_id(stop, :details),
      partial: "itineraries/explanation",
      locals: {
        stop: stop,
        itinerary: stop.itinerary, # Necesario para las rutas del parcial
        explanation: explanation_text,
        user_vibe: user_vibe # Lo pasamos de nuevo para la siguiente fase
      }
    )
  end
end
