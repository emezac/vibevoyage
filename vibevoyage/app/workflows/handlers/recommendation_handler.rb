# app/workflows/handlers/recommendation_handler.rb

module WorkflowHandlers
  class RecommendationHandler
    def self.call(input_data, workflow_variables)
      interests = workflow_variables.dig('parse_vibe', 'handler_result', 'interests')
      city = workflow_variables.dig('parse_vibe', 'handler_result', 'city')

      # Llama al servicio, que a su vez llama a la herramienta registrada
      recommendations = RdawnApiService.qloo_recommendations(interests: interests, city: city)

      if recommendations[:success]
        # Devuelve los datos para la siguiente tarea en el workflow
        { success: true, recommendations: recommendations[:data] }
      else
        # Maneja el error
        { success: false, error: recommendations[:error] }
      end
    end
  end
end