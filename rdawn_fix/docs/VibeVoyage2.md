
### **6. Arquitectura Técnica Detallada y Stack Tecnológico**

Para construir VibeVoyage, `rdawn` no operará en el vacío. Se apoyará en una arquitectura Rails bien estructurada que está diseñada para la interactividad y la escalabilidad.

*   **Framework Principal:** Ruby on Rails 8.0
*   **Motor Agéntico:** `rdawn` (la gema que contiene toda la lógica de orquestación de workflows).
*   **Frontend:** Hotwire (Turbo y Stimulus). Esto es **crucial**. Nos permite crear una experiencia de usuario de tipo SPA (Single Page Application) reactiva y en tiempo real con la simplicidad del desarrollo del lado del servidor, lo cual es perfecto para mostrar las actualizaciones del agente `rdawn` al instante.
*   **Base de Datos:** PostgreSQL. Ideal por su robustez y sus capacidades para futuras búsquedas geoespaciales (PostGIS).
*   **Comunicaciones Externas:**
    *   **Gema `httpx`:** Para crear el `Tool` que se comunicará con la API de Qloo y la API de Mapas de forma eficiente y concurrente.
    *   **Gema `openai-ruby`:** Será utilizada por la `LLMInterface` de `rdawn` para comunicarse con OpenAI.
*   **Jobs en Segundo Plano:** GoodJob o Sidekiq. El workflow de `rdawn` se ejecutará en un `ActiveJob` para no bloquear la interfaz de usuario mientras el agente "piensa".

**Modelos de Datos Principales (`ActiveRecord`):**

1.  `User`: Modelo estándar de `devise` para la autenticación de usuarios.
2.  `VibeProfile`: Almacenará las "semillas" culturales de un usuario (ej. `user.vibe_profiles.create(category: 'music', entity: 'Radiohead')`). Esto permite al agente aprender y recordar las preferencias del usuario.
3.  `Itinerary`: El objeto principal que guardará los resultados. Tendrá atributos como `name`, `location`, `themes` (JSONB), y el `narrative_html` final. Estará asociado a un `User`.
4.  `ItineraryStop`: Cada parada dentro de un `Itinerary`. Campos: `name`, `description`, `address`, `latitude`, `longitude`, `opening_hours`.

### **7. Diseño de la Experiencia de Usuario (UX/UI): El "Lienzo Mágico"**

La interfaz no será un formulario con múltiples campos. Será un **"lienzo mágico"**: una única área de texto y un espacio debajo donde el itinerario cobra vida.

1.  **Entrada Simple y Conversacional:** El usuario ve una pregunta inspiradora como: *"¿Cuál es tu vibe para hoy?"* o *"Describe tu día perfecto en [Ciudad]"*. La barrera de entrada es mínima.

2.  **Feedback en Tiempo Real (La Magia de `ActionCableTool`):** Tan pronto como el usuario envía su "vibe", el workflow de `rdawn` se dispara en segundo plano. La interfaz, sin recargar, comienza a mostrar actualizaciones en tiempo real gracias a `ActionCableTool`:
    *   `[Task 1] Analizando tu vibe...`
    *   `[Task 2] Consultando el oráculo cultural (Qloo)...`
    *   `[Task 3] Descubriendo temas ocultos...`
    *   `[Task 4] Escribiendo tu historia...`
    *   Esto crea una sensación de que un "conserje" inteligente está trabajando activamente para el usuario. Es teatral y muy efectivo.

3.  **La Revelación Progresiva:** En lugar de mostrar todo el itinerario de golpe, podemos usar `Turbo Streams` para revelarlo sección por sección. Primero, aparecen los temas ("El Recorrido del Cinéfilo Oscuro"). Luego, bajo cada tema, aparecen las paradas con su narrativa.

4.  **Itinerario Interactivo:** El resultado final no es un bloque de texto estático. Cada `ItineraryStop` es un componente interactivo con:
    *   Un enlace para abrir la ubicación en Google Maps.
    *   Un botón para ver fotos (usando la API de Google Places o similar).
    *   Horarios de apertura resaltados en verde si el lugar está abierto ahora.

### **8. Implementación Profunda del Workflow `rdawn`**

Aquí detallamos la configuración de cada tarea `rdawn`, mostrando cómo se pasan los datos.

```ruby
# workflow_definition.rb (o un YAML que se parsea a esto)

VIBE_VOYAGE_WORKFLOW = {
  workflow_id: 'vibe_voyage_curation',
  name: 'Vibe Voyage Experience Curation',
  tasks: [
    {
      task_id: '1_deconstruct_vibe',
      name: 'Deconstruct User Vibe into Seeds',
      is_llm_task: true,
      input_data: {
        prompt: "...", # El prompt detallado de la propuesta anterior
        user_input: "${initial_input.user_vibe}" 
      },
      next_task_id_on_success: '2_expand_taste_graph'
    },
    {
      task_id: '2_expand_taste_graph',
      name: 'Expand Taste Graph via Qloo API',
      tool_name: 'qloo_api_tool', # Herramienta personalizada
      input_data: {
        seeds: "${task_1_deconstruct_vibe.output_data.llm_response.seeds}",
        categories_to_find: ['dining', 'music', 'poi', 'fashion']
      },
      next_task_id_on_success: '3_synthesize_themes'
    },
    {
      task_id: '3_synthesize_themes',
      name: 'Synthesize Cultural Themes from Recommendations',
      is_llm_task: true,
      input_data: {
        prompt: "...", # El prompt para encontrar temas
        qloo_recommendations: "${task_2_expand_taste_graph.output_data.result.recommendations}"
      },
      next_task_id_on_success: '4_build_narrative_itinerary'
    },
    {
      task_id: '4_build_narrative_itinerary',
      name: 'Build Narrative Itinerary for Each Theme',
      # Este sería un "Dynamic Task" que itera sobre los temas
      # y ejecuta una LLMTask para cada uno.
      type: 'DirectHandlerTask',
      handler: 'NarrativeBuilder#build_for_themes',
      input_data: {
        themes: "${task_3_synthesize_themes.output_data.llm_response.themes}"
      },
      next_task_id_on_success: '5_enrich_with_logistics'
    },
    {
      task_id: '5_enrich_with_logistics',
      name: 'Enrich with Practical Logistics',
      tool_name: 'maps_api_tool',
      input_data: {
        places: "${task_4_build_narrative_itinerary.output_data.result.places}"
      },
      next_task_id_on_success: '6_present_final_itinerary'
    },
    {
      task_id: '6_present_final_itinerary',
      name: 'Present Final Itinerary to User',
      tool_name: 'action_cable_tool',
      input_data: {
        action_type: 'turbo_stream',
        streamable: "itinerary_channel:${initial_input.user_id}",
        target: 'itinerary_results',
        turbo_action: 'replace',
        partial: 'itineraries/final_display',
        locals: {
          narratives: "${task_4_build_narrative_itinerary.output_data.result.narratives}",
          logistics: "${task_5_enrich_with_logistics.output_data.result.logistics_data}"
        }
      }
    }
  ]
}
```**Nota sobre la Tarea 4:** Este es un patrón avanzado. Un `DirectHandlerTask` puede actuar como un "sub-orquestador", iterando sobre una lista y ejecutando otras tareas o llamadas a LLM, para luego agregar los resultados. Esto demuestra la flexibilidad de `rdawn`.

### **9. Estrategia de Monetización y Go-to-Market (Para impresionar a Jason Calacanis)**

Este no es solo un proyecto de hackathon; es el MVP de un negocio escalable.

*   **Freemium:**
    *   **VibeVoyage Free:** 1 itinerario por mes, en una sola ciudad, con un máximo de 5 "semillas" de gustos. Suficiente para enganchar a los usuarios.
*   **Suscripción Premium:**
    *   **VibeVoyage Pro ($7/mes):** Itinerarios ilimitados, planificación de viajes de varios días, guardar y compartir itinerarios, y la capacidad de refinar los gustos ("me gusta esto, pero no aquello").
*   **B2B - El Verdadero Escalado:**
    *   **VibeVoyage Concierge API:** Una API para que hoteles boutique, agencias de viajes de lujo y planificadores de eventos la integren en sus servicios. Un hotel podría ofrecer a cada huésped un itinerario personalizado basado en su perfil al momento del check-in. Este es un mercado de alto valor.

**Estrategia de Adquisición:**
1.  **Marketing de Contenidos:** Crear itinerarios de ejemplo para ciudades populares y publicarlos en blogs de viajes y redes sociales (TikTok, Instagram) para mostrar el poder narrativo del producto.
2.  **Asociaciones:** Colaborar con influencers de viajes para que usen la herramienta y compartan sus "itinerarios VibeVoyage".
3.  **Product-Led Growth:** El modelo Freemium y la facilidad para compartir itinerarios permitirán que el producto crezca orgánicamente.

### **10. Plan de Trabajo Concreto para el Hackathon (1 Mes)**

*   **Semana 1: Cimientos y Conectividad.**
    *   Día 1-2: Montar la aplicación Rails 8 con Hotwire y `devise`. Diseñar los modelos de `ActiveRecord`.
    *   Día 3-4: Integrar la gema `rdawn`.
    *   Día 5-7: Construir y probar las herramientas (`ToolTask`) para la API de Qloo y la API de Mapas. Registrar un `api_key` de Qloo.
*   **Semana 2: El Cerebro del Agente.**
    *   Día 8-11: Implementar y refinar el workflow de `rdawn` completo, desde la Tarea 1 a la 6. La mayor parte del tiempo se dedicará a la **ingeniería de prompts** para las Tareas 1, 3 y 4 para obtener resultados de alta calidad.
    *   Día 12-14: Construir la lógica del `DirectHandlerTask` para la Tarea 4 (el "sub-orquestador").
*   **Semana 3: La Experiencia Mágica.**
    *   Día 15-18: Diseñar la interfaz de usuario del "lienzo mágico".
    *   Día 19-21: Integrar `ActionCableTool` y `Turbo Streams` para lograr el feedback en tiempo real y la presentación progresiva del itinerario.
*   **Semana 4: Pulido, Despliegue y Presentación.**
    *   Día 22-25: Pruebas exhaustivas. Refinar el estilo visual.
    *   Día 26-27: Desplegar la aplicación en un servicio como Heroku o Fly.io para el demo funcional.
    *   Día 28-30: Grabar y editar el video de 3 minutos, asegurándose de que cuente una historia convincente que destaque la originalidad del proyecto.

---

### **Conclusión de la Propuesta Profunda**

**VibeVoyage** no es una simple capa sobre una API. Es una **plataforma de curaduría de experiencias** que demuestra una comprensión profunda de cómo la **data estructurada (Qloo)** y la **creatividad no estructurada (LLM)** pueden ser orquestadas por un **motor agéntico robusto (`rdawn`)** para crear un producto genuinamente nuevo y valioso.

Abordamos el desafío de frente, mostrando no solo *qué* construimos, sino *cómo* lo construimos de una manera inteligente, escalable y centrada en el usuario. Esta es una propuesta diseñada para ganar.
