# frozen_string_literal: true

# Defines the module for grouping workflows.
# The folder structure app/workflows/workflows/ allows Rails to correctly find
# this constant ::Workflows::VibeVoyageWorkflow.
module Workflows
  class VibeVoyageWorkflow
    # This class method defines the entire workflow structure.
    # It returns an array of hashes, where each hash is a task definition.
    # The ProcessVibeJob or another orchestrator will use this to build Rdawn::Task instances.
    def self.tasks
      [
       {
          # Task 1: Use an LLM to parse the user's free-form text into structured data.
          id: :parse_vibe,
          type: :llm_task,
          prompt: <<-PROMPT.strip,
            Analyze the following text and extract key cultural entities. Your goal is to generate clean, useful JSON for a recommendation API.

            CRITICAL RULES FOR CITY IDENTIFICATION:
            1. Look for specific city names mentioned explicitly
            2. If a state/region is mentioned, identify the main cultural city:
               - "Yucatan" or "Yucatán" → "Mérida" 
               - "California" → "Los Angeles" or "San Francisco" (choose based on context)
               - "Tuscany" → "Florence"
               - "Andalusia" → "Seville" 
               - "Catalonia" → "Barcelona"
               - "Bavaria" → "Munich"
            3. If country only is mentioned, use the cultural capital:
               - "Mexico" → "Mexico City" (unless state/region specified)
               - "France" → "Paris"
               - "Italy" → "Rome"
               - "Spain" → "Madrid" 
               - "Germany" → "Berlin"
               - "Japan" → "Tokyo"
            4. Regional food/cultural references help identify locations:
               - "sopa de lima", "cochinita pibil", "mezcal" + Mexico → likely "Mérida" (Yucatan)
               - "paella" → "Valencia" 
               - "tapas" → "Madrid" or "Barcelona"
               - "ramen" → "Tokyo"
               - "pasta" → "Rome"
            5. If NO location is mentioned at all, use "New York" as default
            6. ALWAYS use the full, standardized city name in English (e.g., "Mérida" not "Yucatan")

            7. Extract ONLY specific place types or venue categories (e.g., 'restaurant', 'bar', 'museum', 'cinema', 'bookstore', 'park'). 
               DO NOT include vague adjectives like 'quiet', 'bohemian', 'trendy'.

            8. Identify general experience themes (e.g., 'culture', 'gastronomy', 'nightlife', 'history', 'nature', 'art').

            9. Respond ONLY with valid JSON, no markdown or extra text.

            User Text: '{{input}}'

            Example outputs:
            
            For "Una tarde agradable en Yucatan Mexico probando sopa de lima con tequila":
            {
              "city": "Mérida",
              "interests": ["restaurant", "tequila bar", "soup"],
              "preferences": ["gastronomy", "culture"]
            }

            For "A great day in Toronto Canada with wine and the best meat cuts":
            {
              "city": "Toronto",
              "interests": ["steakhouse", "wine bar"],
              "preferences": ["gastronomy", "luxury"]
            }

            For "a beautiful day in Madrid with tapas and beer":
            {
              "city": "Madrid",
              "interests": ["tapas bar", "brewery"],
              "preferences": ["gastronomy", "culture"]
            }

            For "Exploring California's wine country and art galleries":
            {
              "city": "San Francisco",
              "interests": ["winery", "art gallery"],
              "preferences": ["art", "gastronomy", "culture"]
            }

            For "Tokyo ramen and temples":
            {
              "city": "Tokyo",
              "interests": ["ramen restaurant", "temple"],
              "preferences": ["gastronomy", "culture", "history"]
            }
          PROMPT
          next_task_id: :qloo_recommendations
        },
        {
          # Task 2: Use the extracted interests to get recommendations from Qloo.
          id: :qloo_recommendations,
          type: :tool_task,
          tool: 'qloo_api',
          # Pass the city and interests
          input_mapping: {
            city: '{{parse_vibe_output.city}}',
            interests: '{{parse_vibe_output.interests}}',
            preferences: '{{parse_vibe_output.preferences}}'
          },
          next_task_id: :google_places
        },
        {
          # Task 3: Search for places in the city using Google Places API.
          id: :google_places,
          type: :tool_task,
          tool: 'maps_api',
          input_mapping: {
            city: '{{parse_vibe_output.city}}',
            query_terms: '{{parse_vibe_output.interests}}'
          },
          next_task_id: :curate_stops
        },
        {
          # Task 4: Use an LLM to select the best stops and add context.
          id: :curate_stops,
          type: :llm_task,
          prompt: <<-PROMPT.strip,
            You are an expert travel curator for {{parse_vibe_output.city}}. You have received cultural recommendations and places in this specific city.
            
            Your task is to select the best 3-4 stops for a cohesive and memorable itinerary, ensuring they are:
            1. Actually located in {{parse_vibe_output.city}}
            2. Diverse in type and experience
            3. Culturally authentic to the city
            4. Logistically feasible to visit in one day

            For each selected stop, create a JSON object with:
            - "name": Exact venue name
            - "description": Evocative 1-2 sentence description highlighting what makes it special
            - "address": Full address in {{parse_vibe_output.city}}
            - "cultural_reason": Why this connects with the user's vibe and the city's character
            - "estimated_time": Suggested visit duration (e.g., "1-2 hours")

            Original user preferences: {{parse_vibe_output.preferences}}
            User interests: {{parse_vibe_output.interests}}

            Input data (Qloo + Google Places):
            {{qloo_and_google_data}}

            Respond ONLY with a valid JSON array. Verify all locations are actually in {{parse_vibe_output.city}}.
          PROMPT
          next_task_id: :build_narrative
        },
        {
          # Task 5: Use a Ruby handler to build the final HTML narrative.
          id: :build_narrative,
          type: :handler_task,
          handler: 'WorkflowHandlers::NarrativeBuilder',
          # Pass all the context including the city
          input_mapping: {
            city: '{{parse_vibe_output.city}}',
            curated_stops: '{{curate_stops_output}}',
            original_vibe: '{{input}}',
            user_preferences: '{{parse_vibe_output.preferences}}'
          },
          next_task_id: :finalize
        },
        {
          # Task 6: Send the final result to the UI via ActionCable.
          id: :finalize,
          type: :tool_task,
          tool: 'action_cable',
          next_task_id: nil
        }
      ]
    end

    # Helper method to validate city names (can be used by tools)
    def self.standardize_city_name(city_input)
      city_mappings = {
        'cdmx' => 'Mexico City',
        'mexico df' => 'Mexico City',
        'df' => 'Mexico City',
        'ciudad de mexico' => 'Mexico City',
        'nyc' => 'New York',
        'new york city' => 'New York',
        'sf' => 'San Francisco',
        'la' => 'Los Angeles',
        'roma' => 'Rome',
        'münchen' => 'Munich',
        'tokio' => 'Tokyo',
        'kyoto' => 'Kyoto',
        'osaka' => 'Osaka',
        'london' => 'London',
        'paris' => 'Paris',
        'berlin' => 'Berlin',
        'madrid' => 'Madrid',
        'barcelona' => 'Barcelona',
        'amsterdam' => 'Amsterdam',
        'prague' => 'Prague',
        'vienna' => 'Vienna',
        'budapest' => 'Budapest',
        'warsaw' => 'Warsaw',
        'stockholm' => 'Stockholm',
        'copenhagen' => 'Copenhagen',
        'helsinki' => 'Helsinki',
        'oslo' => 'Oslo',
        'toronto' => 'Toronto',
        'montreal' => 'Montreal',
        'vancouver' => 'Vancouver'
      }

      normalized = city_input.to_s.downcase.strip
      city_mappings[normalized] || city_input.titleize
    end
  end
end
