### **Documento de Requisitos de Producto (PRD): VibeVoyage**

**Versión:** Hackathon 1.0
**Fecha:** 20 de julio de 2025
**Proyecto:** VibeVoyage - El Curador de Itinerarios Agéntico

#### **1. Resumen Ejecutivo (El "Elevator Pitch")**

VibeVoyage es una aplicación web inteligente que redefine la planificación de experiencias al transformarla de una búsqueda transaccional a una **curaduría narrativa**. El usuario describe su "vibe" cultural (gustos en cine, música, arte, comida) en lenguaje natural. Nuestro sistema, impulsado por un agente de IA `rdawn` nativo de Ruby on Rails, utiliza la API de Qloo para decodificar estas preferencias en un "grafo de gustos" profundo y trans-dominio. Luego, en lugar de devolver una simple lista, el agente orquesta un LLM para **tejer estas afinidades culturales en un itinerario temático y cronológico completo**, convirtiendo un día en una ciudad en una historia personal que el usuario está a punto de vivir. VibeVoyage no te da una lista de "qué hacer"; te entrega una narrativa de "quién ser" por un día.

#### **2. Alineación con los Requisitos del Qloo Global Hackathon**

Este proyecto está diseñado desde su núcleo para sobresalir en los criterios del hackathon:

*   **Integración LLM + Qloo API:** La sinergia es el corazón del proyecto. El LLM se usa para el razonamiento (deconstruir la entrada del usuario, sintetizar temas), mientras que la **API de Qloo se utiliza para su capacidad única de descubrimiento de afinidades trans-dominio**, proporcionando la materia prima cultural que el LLM por sí solo no posee.
*   **Demostración de Valor de Qloo:** No usamos Qloo para obtener "recomendaciones de películas para fans de Tarantino". Lo usamos para responder preguntas mucho más complejas como: *"¿A qué tipo de restaurante, bar, librería y destino de viaje iría un fan de las películas de Tarantino?"*. Demostramos cómo Qloo conecta el comportamiento y el contexto cultural de manera profunda.
*   **Caso de Uso:** Encaja perfectamente en las categorías de **"Taste-based personal assistants"** y **"Smart lifestyle/travel/dining/fashion interfaces"**.
*   **Originalidad y Atractivo para Inversión (Premio Jason Calacanis):** La idea del "itinerario narrativo" es una innovación sobre los motores de recomendación estándar. Tiene un modelo de negocio claro (Freemium, Pro, B2B API) y un inmenso potencial de aplicación en el mundo real, convirtiéndolo de un prototipo a un producto invertible.

#### **3. El Problema: La Tiranía de la Popularidad y la Parálisis por Análisis**

La planificación de viajes y ocio actual está rota. Los usuarios se enfrentan a dos frustraciones principales:
1.  **Recomendaciones Genéricas:** Las plataformas existentes (Google Maps, TripAdvisor) optimizan para la popularidad, llevando a experiencias turísticas saturadas y poco auténticas que no resuenan con los gustos personales del individuo.
2.  **Carga Cognitiva Masiva:** Para evitar lo anterior, el usuario se convierte en un investigador a tiempo completo, saltando entre docenas de blogs, guías y mapas para intentar conectar manualmente los puntos de una experiencia culturalmente coherente.

El resultado es una experiencia de usuario deficiente: o bien se conforman con lo genérico o se rinden ante la abrumadora tarea de la planificación personalizada.

#### **4. La Solución: VibeVoyage, el Curador de Experiencias**

VibeVoyage aborda este problema como un **curador de arte humano**, no como un motor de búsqueda. El proceso es conversacional, creativo y, finalmente, práctico.

**User Journey:**
1.  **El Lienzo Mágico:** El usuario se encuentra con una interfaz simple y evocadora: un área de texto que pregunta: *"Describe tu vibe perfecto para un día en [Ciudad]"*.
2.  **La Conversación:** El usuario escribe en lenguaje natural. *Ej: "Quiero un sábado en la Ciudad de México. Me encanta el cine de Guillermo del Toro, los tacos al pastor, el rock en español de los 90 y el arte surrealista."*
3.  **La Magia en Tiempo Real:** El usuario envía la consulta. La interfaz no se queda estática. Gracias a la integración con `rdawn` y su **`ActionCableTool`**, el usuario ve cómo el agente "piensa" en tiempo real, mostrando el progreso del workflow:
    *   `[✓] Vibe analizado.`
    *   `[✓] Consultando oráculo cultural (Qloo)...`
    *   `[↻] Sintetizando temas ocultos...`
    *   `[... ] Escribiendo tu historia...`
4.  **La Revelación:** En lugar de una lista, aparece un itinerario narrativo completo, dividido en temas creativos como **"El Recorrido del Cinéfilo Oscuro"** y **"La Ruta del Sabor y Sonido"**, cada uno con paradas lógicas, descripciones evocadoras y toda la información práctica necesaria (mapas, horarios, enlaces).

#### **5. Arquitectura Técnica y Ejecución con `rdawn`**

La robustez de la idea se sustenta en una arquitectura de software moderna y bien estructurada, nativa de Ruby on Rails.

*   **Stack Tecnológico:**
    *   **Backend:** Ruby on Rails 8.0
    *   **Motor Agéntico:** `rdawn` (gema interna)
    *   **Frontend:** Hotwire (Turbo & Stimulus) para una experiencia reactiva sin la complejidad de un framework JS pesado.
    *   **Base de Datos:** PostgreSQL
    *   **APIs Externas:** Qloo Taste AI™, OpenAI (GPT-4o), Google Maps API.

*   **El Workflow Detallado de `rdawn` (`curate_experience`):**
    El proceso completo es orquestado por el `WorkflowEngine` de `rdawn`, ejecutando una serie de tareas interconectadas.

| ID Tarea | Nombre | Tipo de Tarea | Descripción y Propósito |
| :--- | :--- | :--- | :--- |
| **1_deconstruct**| Deconstruir Vibe del Usuario | `LLMTask` | Recibe el texto del usuario (`"${initial_input.user_vibe}"`) y usa un LLM para extraer entidades culturales clave en un formato JSON estructurado, listo para la API de Qloo. **Input:** Lenguaje natural. **Output:** JSON de "semillas" culturales. |
| **2_expand**| Expandir Grafo de Gustos | `ToolTask` | Utiliza una herramienta personalizada (`qloo_api_tool`) que toma las semillas de la tarea 1 y consulta la API de Qloo para encontrar afinidades en dominios como `dining`, `poi`, `music`. **Input:** Semillas JSON. **Output:** Un conjunto rico y no estructurado de recomendaciones conectadas. |
| **3_synthesize**| Sintetizar Temas Narrativos | `LLMTask` | **(El paso creativo clave)**. Recibe la lista de recomendaciones de Qloo y usa un LLM para realizar una tarea de razonamiento: agrupar los lugares y actividades en 2-3 temas coherentes y evocadores. **Input:** Lista de entidades. **Output:** JSON con temas narrativos (ej. `{"tema": "El Recorrido del Cinéfilo Oscuro", "lugares": [...]}`). |
| **4_build**| Construir Itinerario Narrativo | `DirectHandlerTask`| Un "sub-orquestador". Este handler de Ruby itera sobre los temas de la tarea 3. Para cada tema, ejecuta dinámicamente una `LLMTask` que toma los lugares y los teje en una historia cronológica (mañana, tarde, noche) con un tono inspirador. **Input:** Temas JSON. **Output:** Texto narrativo para cada tema. |
| **5_enrich**| Enriquecer con Datos Logísticos | `ToolTask` | Usa una herramienta (`maps_api_tool`) que parsea los nombres de los lugares de la narrativa de la tarea 4 y consulta la API de Google Maps para obtener direcciones, horarios, coordenadas y enlaces. **Input:** Nombres de lugares. **Output:** Datos logísticos estructurados. |
| **6_present**| Presentar Itinerario Final | `ToolTask` | Usa la `ActionCableTool` de `rdawn` para combinar la narrativa (Tarea 4) y la logística (Tarea 5) y las envía a través de un `Turbo Stream` al navegador del usuario, actualizando la UI en tiempo real sin recargar la página. **Input:** Narrativa y logística. **Output:** Actualización de la UI del cliente. |

#### **6. Modelo de Negocio y Potencial en el Mundo Real**

VibeVoyage está diseñado como un producto viable con un claro camino hacia la monetización.

*   **Freemium:** 1 itinerario gratuito al mes para demostrar el valor y fomentar el crecimiento viral a través de itinerarios compartibles.
*   **Suscripción Pro ($7/mes):** Itinerarios ilimitados, planificación de viajes de varios días, guardado de perfiles de "vibe", y opciones de personalización avanzadas ("refinar itinerario").
*   **B2B - VibeVoyage Concierge API:** El modelo de mayor escalabilidad. Ofrecer una API de marca blanca para que hoteles boutique, aerolíneas, y agencias de viajes de lujo puedan ofrecer experiencias híper-personalizadas a sus clientes como un servicio de valor añadido.

Este modelo posiciona a VibeVoyage no solo como una app para consumidores, sino como una plataforma de inteligencia cultural para toda la industria de la hospitalidad y el turismo.

#### **7. Plan para el Video de Demostración (Menos de 3 minutos)**

*   **(0:00 - 0:30) El Problema:** Escenas rápidas mostrando la frustración de la planificación de viajes: múltiples pestañas abiertas, listas genéricas de "top 10", un mapa confuso.
*   **(0:30 - 1:00) La Solución:** Introducir la interfaz limpia y minimalista de VibeVoyage. Mostrar al usuario escribiendo su "vibe" en el "lienzo mágico".
*   **(1:00 - 1:45) La Magia en Acción:** Mientras el usuario espera, mostrar el feed de progreso del agente `rdawn` en la UI, comunicando visualmente el proceso de pensamiento de la IA. Esto es clave para mostrar la complejidad técnica de forma sencilla.
*   **(1:45 - 2:30) La Revelación:** El itinerario narrativo final aparece elegantemente en la pantalla. Hacer un scroll rápido para mostrar los temas creativos, las descripciones evocadoras y los detalles prácticos (mapas, horarios).
*   **(2:30 - 3:00) La Visión:** Un cierre rápido que resume la propuesta de valor: "VibeVoyage: no solo planifiques tu viaje, vive tu historia". Mencionar el stack tecnológico (Qloo + LLM + `rdawn`) y el potencial de negocio.

#### **8. Repositorio de Código y Demo Funcional**

*   **Repositorio:** El código será público en GitHub, con un `README.md` detallado que explica la arquitectura, la configuración y cómo ejecutar el proyecto. Incluirá documentación clara sobre el workflow de `rdawn`.
*   **Demo Funcional:** La aplicación se desplegará en una plataforma como Heroku o Fly.io, con una URL pública para que los jueces puedan probar la experiencia completa de principio a fin.

