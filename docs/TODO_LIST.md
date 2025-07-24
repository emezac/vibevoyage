### **TODO List Definitiva: Construcción de VibeVoyage (con Diseño y Pruebas Integradas)**

**Objetivo General:** Desarrollar un prototipo funcional y pulido de VibeVoyage, fiel al `ui_design.html` y con una sólida base de pruebas, listo para el Qloo Global Hackathon.

**Leyenda de Prioridades:**
*   🔴 **Crítico:** Tarea bloqueante o esencial para la funcionalidad mínima.
*   🟡 **Importante:** Necesario para una característica completa y una buena experiencia.
*   🟢 **Deseable:** Mejora, pulido o "nice-to-have".

---

### **🚀 Fase 0: Preparación y Andamiaje del Proyecto (Días 1-3)**


*   **0.1: Entorno y Creación de la App**
    *   `[x]` 🔴 Verificar entorno: Ruby 3.3+, Rails 8.0+, PostgreSQL.
    *   `[x]` 🔴 Crear la aplicación Rails: `rails new vibevoyage -d postgresql -c tailwind`.
    *   `[x]` 🔴 Configurar la base de datos: `rails db:create`.
    *   `[x]` 🔴 Inicializar y configurar el repositorio de Git con GitHub.


*   **0.2: Gemas y Configuración Inicial**
    *   `[x]` 🔴 Añadir gemas al `Gemfile`: `devise`, `dotenv-rails`, `httpx`, `rdawn` (local), `rspec-rails`, `factory_bot_rails`, `faker`.
    *   `[x]` 🔴 Instalar gemas: `bundle install`.
    *   `[x]` 🔴 **Configurar RSpec:** `rails g rspec:install`.
    *   `[x]` 🔴 Configurar `.env` con las claves de API y añadirlo al `.gitignore`.
    *   `[x]` 🔴 **Instalar y configurar `devise`:**
        *   `rails g devise:install`
        *   `rails g devise User`
        *   `rails db:migrate`


*   **0.3: Modelos de Datos y Pruebas de Modelos**
    *   `[x]` 🔴 **Generar modelos:**
        *   `rails g model Itinerary name:string location:string themes:jsonb narrative_html:text user:references`
        *   `rails g model ItineraryStop name:string description:text address:string latitude:float longitude:float opening_hours:string itinerary:references`
        *   `rails g model VibeProfile category:string entity:string user:references`
    *   `[x]` 🔴 Ejecutar migración: `rails db:migrate`.
    *   `[x]` 🔴 **Pruebas de Modelos (`spec/models/`):**
        *   `[x]` **`user_spec.rb`:** Testear que un `User` `has_many :itineraries` y `has_many :vibe_profiles`.
        *   `[x]` **`itinerary_spec.rb`:** Testear que un `Itinerary` `belongs_to :user` y `has_many :itinerary_stops`.
        *   `[x]` **`itinerary_stop_spec.rb`:** Testear que un `ItineraryStop` `belongs_to :itinerary`.
        *   `[x]` **`vibe_profile_spec.rb`:** Testear que un `VibeProfile` `belongs_to :user`.

---

### **🧩 Fase 1: Cimientos y Conectividad (Backend Core) (Días 4-8)**

*   **1.1: Integración y Configuración de `rdawn`**
    *   `[x]` 🔴 Instalar `rdawn`: `rails g rdawn:rails:install`.
    *   `[x]` 🔴 Configurar `config/initializers/rdawn.rb` con las claves de API y la integración de Active Job.

*   **1.2: Herramientas Personalizadas y sus Pruebas**
    *   `[x]` 🔴 **`QlooApiTool` (`app/tools/qloo_api_tool.rb`):**
        *   Implementada la lógica para llamar a la API de Qloo.
    *   `[x]` 🔴 **Pruebas para `QlooApiTool` (`spec/tools/qloo_api_tool_spec.rb`):**
        *   Tests completados: mockeo de llamada a `HTTPX.get`, verificación de respuesta exitosa y manejo de errores (401/500).
    *   `[x]` 🟡 **`MapsApiTool` (`app/tools/maps_api_tool.rb`):**
        *   `[x]` Lógica para consumir la API de Google Places implementada. ✅
    *   `[x]` 🟡 **Pruebas para `MapsApiTool` (`spec/tools/maps_api_tool_spec.rb`):**
        *   Tests completados: mockeo de la API de Google, verificación de respuesta exitosa y manejo de errores.
    *   `[x]` 🔴 **Registrar herramientas en `rdawn`:** Código de registro añadido en `config/initializers/rdawn.rb`.

---

### **🧠 Fase 2: El Cerebro del Agente (Workflow `rdawn`) (Días 9-15)**

*   **2.1: Definición y Orquestación del Workflow**
    *   `[x]` 🔴 Crear `app/workflows/vibe_voyage_workflow.rb` y definir la estructura completa de 6 tareas.
    *   `[x]` 🔴 **Ingeniería de Prompts:** Iterar y refinar los prompts para las tareas `LLMTask` (Tareas 1, 3, 4) hasta obtener resultados consistentes y de alta calidad.
    *   `[x]` 🔴 Implementar el handler `NarrativeBuilder` (`app/workflows/handlers/narrative_builder.rb`) para la Tarea 4.
    *   `[x]` 🔴 Crear el `VibeCurationJob` (`rails g job VibeCurationJob`) y añadir la lógica para ejecutar el workflow de `rdawn`.

*   **2.2: Pruebas del Workflow y el Job**
    *   `[x]` 🔴 **Prueba de Integración del Job (`spec/jobs/vibe_curation_job_spec.rb`):**
        *   `[x]` Testear que el job se encola correctamente (`expect { VibeCurationJob.perform_later(...) }.to have_enqueued_job`).
        *   `[x]` Testear la ejecución del job, mockeando las herramientas (`QlooApiTool`, `MapsApiTool`) y la `LLMInterface` de `rdawn` para simular el flujo completo del workflow y verificar que se llama a la `ActionCableTool` al final.

*   **2.3: Rutas y Controlador**
    *   `[x]` 🔴 `rails g controller Itineraries create`.
    *   `[x]` 🔴 Definir la ruta en `config/routes.rb`.
    *   `[x]` 🔴 Implementar la lógica en `ItinerariesController#create` para encolar el `VibeCurationJob`.
    *   `[x]` 🔴 **Pruebas del Controlador (`spec/requests/itineraries_spec.rb`):**
        *   `[x]` Escribir un test para `POST /itineraries` que verifique:
            *   `[x]` Que responde con un status 200 (OK).
            *   `[x]` Que encola un `VibeCurationJob`.
            *   `[x]` Que la respuesta contiene un `<turbo-stream>` que actualiza la UI.

---

### **🎨 Fase 3: La Experiencia Mágica (Frontend con Hotwire) (Días 16-22)**

*   **3.1: Configuración del Diseño Visual (Tailwind)**
    *   `[x]` 🔴 **Abrir `tailwind.config.js`:**
        *   Extender la paleta de colores para incluir la del `ui_design.html`: `deep-space`, `terracotta`, `sage`, `sand`.
        *   Extender las fuentes para incluir `font-display: ['Playfair Display', 'serif']`.
    *   `[x]` 🟡 En `app/assets/stylesheets/application.tailwind.css`, definir la clase `.glass-card` con `@apply` para reutilizarla, incluyendo `backdrop-blur`.

*   **3.2: Implementación de la UI por Componentes**
    *   `[x]` 🔴 **Página Principal y "Lienzo Mágico":**
        *   `rails g controller Home index` y establecer la ruta raíz.
        *   En `app/views/home/index.html.erb`, maquetar la sección del Héroe, el formulario y el contenedor `<turbo-frame>` principal, replicando la estructura del `ui_design.html`.
    *   `[ ]` 🟡 **Componente "AI Thinking":**
        *   Crear el parcial `app/views/itineraries/_thinking.html.erb`.
        *   Maquetar la tarjeta de "pensamiento" con la animación de pulso y el área de logs, exactamente como en `ui_design.html`.
    *   `[ ]` 🟡 **Componente "Itinerary Stop":**
        *   Crear el parcial `app/views/itineraries/_stop.html.erb`.
        *   Maquetar la tarjeta de una parada del itinerario (imagen, título, conexión cultural, barra de "Vibe Match"). Este parcial recibirá variables locales (`stop`).
    *   `[ ]` 🟡 **Vista de Resultados Finales:**
        *   Crear el parcial `app/views/itineraries/_results.html.erb`.
        *   Este parcial renderizará el título del itinerario y luego iterará sobre las paradas, renderizando el parcial `_stop` para cada una.

*   **3.3: Integración de Tiempo Real y Pruebas de Sistema**
    *   `[ ]` 🔴 **Action Cable:**
        *   `rails g channel Itinerary`.
        *   Implementar la lógica de suscripción en `app/channels/itinerary_channel.rb`.
        *   Añadir `<%= turbo_stream_from ... %>` en la vista principal.
    *   `[ ]` 🔴 **Prueba de Sistema (El test más importante):**
        *   `rails g system_test ItineraryCreation`
        *   En `spec/system/itinerary_creation_spec.rb`, escribir el flujo completo con Capybara.

---

### **✅ Fase 4: Pulido, Despliegue y Presentación (Días 23-30)**

*   **4.1: Manejo de Errores en la UI**
    *   `[ ]` 🟡 En el workflow de `rdawn`, definir `next_task_id_on_failure` para las tareas críticas.
    *   `[ ]` 🟡 Crear una tarea `handle_failure` que use `action_cable_tool` para enviar un `Turbo Stream` que renderice un parcial `_error.html.erb` en la UI, mostrando un mensaje amigable.
    *   `[ ]` 🟢 Añadir una prueba de sistema para el caso de error.

*   **4.2: Pulido Final del Diseño**
    *   `[ ]` 🟢 Revisar la aplicación desplegada en un dispositivo móvil y ajustar el diseño responsivo con Tailwind.
    *   `[ ]` 🟢 Implementar las animaciones sutiles (`.fade-in-up`, `.timeline-path`) usando CSS y, si es necesario, un poco de JavaScript con Stimulus.

*   **4.3: Documentación y Despliegue**
    *   `[ ]` 🔴 Actualizar `README.md` del proyecto con instrucciones claras y una descripción final.
    *   `[ ]` 🔴 Desplegar la aplicación en Heroku/Fly.io y configurar las variables de entorno.
    *   `[ ]` 🔴 Probar exhaustivamente la aplicación en producción.

*   **4.4: Preparación de la Entrega**
    *   `[ ]` 🔴 **Grabar el video de demo (< 3 min):** Usar la aplicación desplegada y seguir el guion del PRD.
    *   `[ ]` 🔴 **Escribir la descripción final del proyecto.**
    *   `[ ]` 🔴 **Ejecutar toda la suite de pruebas una última vez:** `bundle exec rspec`. Asegurarse de que todo esté en verde.
    *   `[ ]` 🔴 **Revisar todos los requisitos del hackathon y enviar.**


### **✅ Fase 4: Pulido, Despliegue y Presentación (Continuación y Expansión) (Días 23-30)**

*   **4.1: Manejo de Errores en la UI (Ya definido, sin cambios)**
    *   `[ ]` 🟡 En el workflow `rdawn`, definir `next_task_id_on_failure`.
    *   `[ ]` 🟡 Crear una tarea `handle_failure` que use `action_cable_tool` para mostrar un error amigable en la UI.
    *   `[ ]` 🟢 **Prueba de Sistema de Fallos (`spec/system/itinerary_failure_spec.rb`):**
        *   Escribir un test que fuerce un fallo (ej. mockeando la API de Qloo para que devuelva un error 500) y verifique que el mensaje de error apropiado se muestra al usuario a través del Turbo Stream.

*   **4.2: Pulido Final del Diseño y Animaciones**
    *   `[ ]` 🟢 **Revisión de Responsividad:** Probar la aplicación en Chrome DevTools en varios tamaños de pantalla (móvil, tablet, escritorio) y ajustar las clases de Tailwind (`md:`, `lg:`) para que la experiencia sea impecable en todos los dispositivos.
    *   `[ ]` 🟢 **Implementación de Animaciones CSS:**
        *   En `app/assets/stylesheets/application.tailwind.css`, añadir las definiciones `@keyframes` para `fadeIn`, `drawPath`, y `pulse` del `ui_design.html`.
        *   Aplicar las clases de animación (`fade-in-up`, `timeline-path`) a los elementos correspondientes en las vistas para darles vida.
    *   `[ ]` 🟢 **JavaScript con Stimulus (Opcional pero recomendado):**
        *   `rails g stimulus AnimationController`.
        *   En `app/javascript/controllers/animation_controller.js`, añadir lógica para aplicar clases de animación cuando los elementos entran en la pantalla (usando `Intersection Observer`), para un efecto más dinámico al hacer scroll.

*   **4.3: Documentación y Despliegue (Ya definido, sin cambios)**
    *   `[ ]` 🔴 Actualizar `README.md` del proyecto.
    *   `[ ]` 🔴 Desplegar la aplicación en Heroku/Fly.io.
    *   `[ ]` 🔴 Probar exhaustivamente la aplicación en el entorno de producción.

*   **4.4: Preparación Detallada de la Entrega**
    *   `[ ]` 🔴 **Guion del Video de Demo:**
        *   Escribir un guion detallado para el video de 3 minutos, segundo a segundo.
        *   **0:00-0:20:** El Problema (imágenes de caos de planificación).
        *   **0:20-0:45:** La Solución (presentar la UI limpia de VibeVoyage).
        *   **0:45-1:15:** La Interacción (grabar la pantalla escribiendo el "vibe").
        *   **1:15-1:45:** La Magia (mostrar el feed de progreso del agente `rdawn`, explicando brevemente qué hace cada paso - "Ahora está consultando a Qloo...").
        *   **1:45-2:30:** El Resultado (hacer scroll por el itinerario final, destacando la narrativa y los detalles prácticos).
        *   **2:30-2:50:** La Visión (resumir el stack y el potencial de negocio).
        *   **2:50-3:00:** Llamada a la acción y logo.
    *   `[ ]` 🔴 **Redacción del Texto de la Propuesta:**
        *   Escribir el texto que acompañará la entrega, usando el PRD como base. Enfocarse en los criterios de evaluación: Uso Inteligente de LLM y Qloo, Implementación Técnica, Originalidad y Potencial de Aplicación.
    *   `[ ]` 🔴 **Limpieza del Repositorio de GitHub:**
        *   Asegurarse de que el `README.md` sea excelente.
        *   Eliminar ramas innecesarias.
        *   Añadir comentarios explicativos en las partes más complejas del código (ej. el handler `NarrativeBuilder`).


### **🏆 Fase 5: Productización y Preparación para el "Bonus Prize" (Días 25-30, en paralelo)**

*Esta fase se enfoca en añadir las características que hacen que VibeVoyage se sienta como un producto real y una oportunidad de negocio, apuntando directamente al "Jason Calacanis Bonus Prize".*

*   **5.1: Funcionalidad de Usuario - Persistencia de Itinerarios**
    *   `[ ]` 🟡 **Actualizar el Job para Guardar Resultados:**
        *   Modificar `VibeCurationJob`. Al final de un workflow exitoso, el job debe parsear el resultado final y crear los registros `Itinerary` y `ItineraryStop` en la base de datos, asociándolos al `User`.
    *   `[ ]` 🟡 **Crear Dashboard de Usuario:**
        *   `rails g controller Dashboard index`.
        *   En `DashboardController#index`, obtener los itinerarios del usuario: `@itineraries = current_user.itineraries.order(created_at: :desc)`.
        *   Crear la vista `app/views/dashboard/index.html.erb` para mostrar una lista de los itinerarios guardados.
    *   `[ ]` 🟡 **Vista de Itinerario Individual:**
        *   Implementar la acción `ItinerariesController#show`.
        *   Crear la vista `app/views/itineraries/show.html.erb` para mostrar un itinerario guardado.
    *   `[ ]` 🟡 **Pruebas de Funcionalidad de Usuario:**
        *   Añadir tests de request/sistema para el dashboard, verificando que un usuario solo puede ver sus propios itinerarios.

*   **5.2: Flujo de Autenticación Pulido**
    *   `[ ]` 🟡 **Personalizar Vistas de Devise:**
        *   `rails g devise:views`.
        *   Aplicar el estilo visual de VibeVoyage (glassmorphism, fuentes, colores) a las vistas de login, registro y recuperación de contraseña en `app/views/devise/`.
    *   `[ ]` 🟡 **Proteger Rutas:**
        *   En `routes.rb`, asegurar que las rutas del dashboard y de creación de itinerarios requieran autenticación (`authenticate :user do ... end`).
    *   `[ ]` 🟡 **Pruebas de Autenticación:**
        *   Añadir tests de sistema que verifiquen que un usuario no autenticado es redirigido al login cuando intenta acceder a páginas protegidas.

*   **5.3: Preparación del Pitch de Inversión**
    *   `[ ]` 🟢 **Crear una sección "Business Case" en el `README.md`:**
        *   **Mercado:** Definir el TAM (Total Addressable Market) para viajeros culturales y el modelo B2B.
        *   **Monetización:** Detallar los planes Freemium, Pro y la API B2B.
        *   **Ventaja Competitiva:** Explicar por qué la combinación de `rdawn` (integración nativa), Qloo (datos culturales) y LLMs (creatividad) crea una barrera de entrada.
    *   `[ ]` 🟢 **Refinar el Video de Demo:**
        *   Asegurarse de que el video no solo muestre *cómo* funciona, sino *por qué* es valioso. Usar texto superpuesto para destacar los beneficios ("De horas de investigación... a segundos de inspiración").

*   **5.4: Checklist Final Pre-Entrega**
    *   `[ ]` 🔴 **Revisión de Requisitos:** Leer una última vez las reglas del hackathon. ¿Cumplimos con todo? (Video < 3 min, repo público, uso de LLM + Qloo, etc.).
    *   `[ ]` 🔴 **Pruebas Finales:** Ejecutar `bundle exec rspec` y `rails test:system` una última vez. Todo debe estar en verde.
    *   `[ ]` 🔴 **Verificación de la Demo en Vivo:** Navegar por la aplicación desplegada como lo haría un juez. ¿Es rápido? ¿Hay errores en la consola? ¿Es intuitivo?
    *   `[ ]` 🔴 **Preparar el Formulario de Envío:** Tener todos los enlaces (repo, video, demo en vivo) y textos listos para copiar y pegar.
    *   `[ ]` 🔴 **¡ENTREGAR!**



