### **Título del Proyecto: VibeVoyage - El Curador de Itinerarios Agéntico**

**Elevator Pitch:** VibeVoyage es una aplicación web inteligente, construida con Ruby on Rails y `rdawn`, que transforma la planificación de viajes y experiencias locales. En lugar de darte una lista de "los 10 mejores lugares", VibeVoyage conversa contigo para entender tu "vibe" cultural único (tus gustos en cine, música, libros, moda) y luego utiliza la API de Qloo para construir un "grafo de gustos" personalizado. Finalmente, un agente de IA orquestado por `rdawn` no solo te recomienda lugares, sino que **crea un itinerario narrativo y temático completo**, convirtiendo un simple viaje en una historia que estás a punto de vivir.

**Caso de Uso Principal:** **Smart lifestyle/travel/dining/fashion interfaces** y **Taste-based personal assistants**.

---

### **1. El Problema: La Tiranía de la Popularidad y la Paradoja de la Elección**

La planificación de viajes moderna está rota. Se basa en dos pilares defectuosos:

1.  **La Popularidad Genérica:** Plataformas como TripAdvisor o Google Maps te muestran lo que es popular, no lo que resuena *contigo*. Terminas en los mismos lugares turísticos que todos los demás, perdiéndote la esencia cultural que realmente te atrae.
2.  **La Investigación Manual Interminable:** Para evitar lo anterior, pasas horas saltando entre blogs, revistas, guías y mapas, tratando de conectar los puntos entre un café que te recomendaron, una galería de arte que viste en Instagram y un bar con la música que te gusta.

El resultado es la parálisis por análisis o una experiencia de viaje decepcionante y poco auténtica.

### **2. La Solución: De Recomendaciones a Experiencias Curadas**

VibeVoyage resuelve esto tratando la planificación de experiencias como un **acto de curaduría creativa**, no como una consulta a una base de datos. La sinergia entre Qloo, un LLM y `rdawn` es la clave:

*   **Qloo (El Experto Cultural):** Proporciona las **conexiones ocultas** entre dominios. Sabe que las personas que aman las películas de Wes Anderson a menudo aprecian las librerías independientes, los cafés con estética retro y la música de folk-rock. Estos son los "hilos" de nuestro tejido cultural.
*   **LLM (El Narrador Creativo):** Toma los hilos de Qloo y los **teje en una historia coherente**. No solo dice "ve a este café y luego a esta librería". Dice: "Comienza tu mañana en 'The Daily Chronicle Café', un lugar que parece sacado de una de tus películas favoritas, donde puedes disfrutar de un café de especialidad mientras lees el periódico. A la vuelta de la esquina, encontrarás 'The Bound Folio', una librería donde el tiempo se detiene...".
*   **`rdawn` (El Director de Orquesta):** Gestiona este complejo diálogo entre el usuario, el LLM y múltiples APIs (Qloo, Mapas, etc.) de una manera **estructurada, fiable y escalable**. Es el motor que permite que la magia suceda sin caos.

### **3. El Flujo de Trabajo Agéntico: Un "Deep Dive" Técnico con `rdawn`**

Aquí es donde demostramos la profundidad técnica. El proceso de VibeVoyage está modelado como un workflow de `rdawn` de múltiples pasos.

**Escenario:** Un usuario escribe: *"Quiero planear un sábado en la Ciudad de México. Me encanta el cine de Guillermo del Toro, los tacos al pastor, el rock en español de los 90 y el arte surrealista."*

**Workflow `rdawn` ("curate_experience"):**

1.  **`Task 1: Deconstruir el Vibe` (`LLMTask`)**
    *   **Propósito:** Traducir la entrada de lenguaje natural en entidades estructuradas que la API de Qloo pueda entender.
    *   **Prompt del LLM:**
        > "Analiza la siguiente descripción de gustos de un usuario. Extrae las entidades culturales clave y clasifícalas en categorías como 'Cine', 'Música', 'Comida', 'Arte'. Formatea la salida como un JSON. Ejemplo: `{'Cine': ['Guillermo del Toro'], 'Música': ['Rock en español 90s'], ...}`"
    *   **Resultado:** Un JSON estructurado: `{ "seeds": [...] }`.

2.  **`Task 2: Expandir el Grafo de Gustos` (`ToolTask` - Qloo API)**
    *   **Propósito:** Usar las "semillas" iniciales para descubrir afinidades culturales ocultas en múltiples dominios.
    *   **Lógica del Handler (`DirectHandlerTask`):**
        *   Toma el JSON de la Tarea 1.
        *   Por cada "semilla" (ej. "Guillermo del Toro"), hace una llamada a la API de Qloo para obtener recomendaciones en otras categorías: `dining`, `travel`, `fashion`, `music`.
        *   Agrega todos los resultados en un gran conjunto de datos de "entidades culturalmente conectadas".
    *   **Valor de Qloo:** Aquí es donde brilla Qloo. Descubriremos que a los fans de GDT podrían gustarles restaurantes con una decoración gótica, bares de cócteles "de autor" o librerías de viejo.

3.  **`Task 3: Sintetizar y Crear Temas` (`LLMTask` - El Paso Mágico)**
    *   **Propósito:** La sinergia clave. El LLM recibe la lista de entidades de Qloo (un restaurante, un bar, un museo, una tienda) y debe encontrar la narrativa que las une.
    *   **Prompt del LLM:**
        > "Eres un curador de experiencias culturales. A continuación, se presenta una lista de lugares y gustos que están conectados culturalmente. Tu tarea es agruparlos en 2 o 3 'temas' o 'conceptos' para un itinerario de un día. Dale a cada tema un nombre evocador y creativo. Por ejemplo: 'El Recorrido del Cinéfilo Oscuro', 'La Ruta del Sabor y Sonido'. Responde solo con un JSON que contenga los temas y las entidades agrupadas."
    *   **Resultado:** El LLM podría agrupar los tacos, el bar de rock y una tienda de discos en el tema "La Ruta del Sabor y Sonido", y el museo de arte, una librería de terror y un cine de arte en "El Recorrido del Cinéfilo Oscuro".

4.  **`Task 4: Construir el Itinerario Narrativo` (`LLMTask`)**
    *   **Propósito:** Convertir los temas en una historia cronológica y atractiva.
    *   **Lógica:** Por cada tema generado en la Tarea 3, se ejecuta una nueva `LLMTask`.
    *   **Prompt del LLM:**
        > "Crea un itinerario narrativo para el tema '${tema.nombre}'. Usa estos lugares: `${tema.lugares}`. Escribe una descripción atractiva para cada parada, conectándolas en una historia coherente. Sugiere un orden lógico (mañana, tarde, noche). El tono debe ser inspirador y personal."
    *   **Resultado:** El texto detallado y evocador que forma el corazón de la experiencia VibeVoyage.

5.  **`Task 5: Enriquecer con Datos Prácticos` (`ToolTask` - Web Search/Maps)**
    *   **Propósito:** Hacer el itinerario funcional.
    *   **Lógica del Handler (`DirectHandlerTask`):**
        *   Parsea los nombres de los lugares del itinerario narrativo de la Tarea 4.
        *   Usa una herramienta (`WebSearchTool` de `rdawn` o una API de mapas) para obtener direcciones, horarios de apertura y enlaces de reserva para cada lugar.
    *   **Resultado:** Datos logísticos para cada parada del itinerario.

6.  **`Task 6: Presentación Final` (`DirectHandlerTask` y `ActionCableTool`)**
    *   **Propósito:** Combinar la narrativa y los datos prácticos en una salida final y actualizar la UI.
    *   **Lógica del Handler:**
        *   Agrega los datos de la Tarea 5 en el itinerario de la Tarea 4.
        *   Usa `ActionCableTool` de `rdawn` para enviar el itinerario completo al navegador del usuario, actualizando la vista en **tiempo real** con `Turbo Streams`. El usuario ve cómo su "vibe" se transforma en un plan tangible sin recargar la página.

### **4. Alineación con los Criterios de Evaluación**

*   **Intelligent & Thoughtful Use of LLMs:**
    *   No usamos el LLM para obtener recomendaciones (eso lo hace Qloo). Lo usamos para tareas de **razonamiento y creatividad**: 1) Deconstruir el lenguaje natural, 2) **Sintetizar temas a partir de datos no estructurados**, y 3) **Generar una narrativa creativa**. Esto extiende *significativamente* las capacidades de Qloo.
*   **Integration with Qloo’s API:**
    *   Nuestra propuesta se basa en la característica más potente y única de Qloo: las **afinidades trans-dominio**. Saltamos de cine a comida a música para construir un perfil de gustos holístico, demostrando un entendimiento profundo del valor de su API.
*   **Technical Implementation & Execution:**
    *   Usamos un stack moderno y robusto (Rails 8, Hotwire) y un framework de agentes (`rdawn`) que demuestra una arquitectura de software bien pensada. El uso de `rdawn` para orquestar el flujo de múltiples pasos muestra una ejecución técnica sólida, no un simple script. La actualización en tiempo real con `ActionCableTool` es un toque técnico elegante.
*   **Originality & Creativity:**
    *   La idea del **"itinerario narrativo"** es mucho más original que una "lista de recomendaciones". Estamos vendiendo una *experiencia curada*, una historia. El concepto de "Vibe" es fresco y resuena con un público moderno que busca autenticidad.
*   **Potential for Real-World Application:**
    *   **Altísimo.** Este es un prototipo que puede convertirse directamente en un producto.
    *   **Modelo de Negocio:** Freemium (1 itinerario/mes), Suscripción Pro (itinerarios ilimitados, más personalización, viajes de varios días), y un modelo B2B para hoteles y agencias de viajes que quieran ofrecer experiencias curadas a sus clientes.
    *   **Atractivo para la Inversión (Jason Calacanis Bonus Prize):** Este proyecto tiene una visión de producto clara, un mercado objetivo definido (viajeros culturales, millennials/gen-z) y un modelo de negocio escalable. Es el tipo de idea que puede atraer a un inversor.

### **5. Flujo de la Demo en 3 Minutos**

1.  **(0:00 - 0:30) El Problema:** Mostrar la pantalla caótica de un planificador de viajes buscando en 5 pestañas diferentes (mapas, blogs, guías).
2.  **(0:30 - 1:30) La Experiencia VibeVoyage:**
    *   Mostrar la interfaz limpia de VibeVoyage.
    *   El usuario escribe la frase: *"Quiero planear un sábado en la Ciudad de México. Me encanta el cine de Guillermo del Toro, los tacos al pastor, el rock en español de los 90 y el arte surrealista."*
    *   Mostrar en la UI cómo el agente `rdawn` actualiza su estado en tiempo real (gracias a `ActionCableTool`): "✔️ Vibe Deconstruido", "✔️ Expandiendo Grafo de Gustos con Qloo", "✔️ Sintetizando Temas...".
3.  **(1:30 - 2:30) La Revelación:**
    *   El itinerario final aparece mágicamente en la pantalla.
    *   Hacer scroll rápidamente para mostrar los **temas creativos** ("El Recorrido del Cinéfilo Oscuro") y la **narrativa atractiva** ("Comienza tu viaje en el Museo de Arte Moderno...").
    *   Mostrar los **detalles prácticos** (mapas, horarios) integrados.
4.  **(2:30 - 3:00) La Visión:**
    *   Terminar con un resumen del stack tecnológico (`rdawn` + Qloo + LLM) y la visión del producto, mencionando el potencial de mercado y el modelo de negocio.

Esta propuesta no solo cumple los requisitos, sino que cuenta una historia convincente sobre el futuro de la IA personalizada, posicionando a VibeVoyage como un proyecto ganador.
