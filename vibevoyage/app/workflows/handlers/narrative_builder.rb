# app/workflows/handlers/narrative_builder.rb
module WorkflowHandlers
  class NarrativeBuilder
    def self.call(input_data, workflow_variables)
      recommendations = input_data['recommendations'] || []
      user_vibe = workflow_variables['original_vibe'] || input_data['original_vibe']
      city = input_data['city'] || 'Unknown City'

      narrative = "<h2>Tu aventura personalizada en #{city}</h2>"
      narrative += "<p>Basado en tu vibe: <strong>#{user_vibe}</strong></p>"

      {
        success: true,
        narrative: narrative,
        city: city,
        recommendations: recommendations
      }
    end
  end
end