### **Continuación: Implementación del Frontend en Ruby on Rails**

#### **1. Configuración del Layout Principal (`application.html.erb`)**

Este archivo será la plantilla base para toda la aplicación. Incluirá las fuentes, los estilos de Tailwind y los tags de Hotwire (Turbo).

**`app/views/layouts/application.html.erb`**
```html
<!DOCTYPE html>
<html lang="es" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>VibeVoyage - Curaduría de Experiencias Narrativas</title>
    
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <!-- Tailwind CSS -->
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>

    <!-- Hotwire (Turbo) y Stimulus -->
    <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;500;600;700;800&family=Playfair+Display:wght@400;500;600;700&display=swap" rel="stylesheet">
    
    <!-- Aquí irían los estilos de :root, animations, etc. que definimos en ui2.html -->
    <!-- Es una buena práctica moverlos a app/assets/stylesheets/base.css o similar -->
</head>
<body class="antialiased bg-deep-space text-primary font-manrope">
    <%= render 'layouts/header' %>
    
    <main class="relative">
        <%= yield %>
    </main>

    <%= render 'layouts/footer' %>
</body>
</html>
```

#### **2. Creación de los Parciales del Layout**

Dividimos el header y el footer en parciales para mantener el código limpio.

**`app/views/layouts/_header.html.erb`**
```html
<header class="sticky top-0 z-50 nav-blur">
    <div class="glass-card mx-4 md:mx-auto md:max-w-7xl mt-4">
        <nav class="container mx-auto px-6 py-4 flex justify-between items-center">
            <a href="/" class="flex items-center gap-3">
                <div class="w-10 h-10 rounded-xl flex items-center justify-center" style="background: linear-gradient(135deg, var(--accent-terracotta), var(--accent-sage));">
                    <svg class="w-6 h-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064" />
                    </svg>
                </div>
                <h1 class="text-3xl font-display font-bold gradient-text">VibeVoyage</h1>
            </a>
            <div class="flex items-center gap-4">
                <%# Aquí iría la lógica de Devise para mostrar "Sign In" o "Sign Out" %>
                <% if user_signed_in? %>
                    <%= link_to "Dashboard", dashboard_path, class: "text-slate-300 hover:text-white transition-colors hidden md:flex items-center gap-2" %>
                    <%= button_to "Sign Out", destroy_user_session_path, method: :delete, class: "glass-card px-6 py-2 rounded-full font-semibold hover:bg-white/10 transition-colors border-0" %>
                <% else %>
                    <%= link_to "Sign In", new_user_session_path, class: "glass-card px-6 py-2 rounded-full font-semibold hover:bg-white/10 transition-colors border-0" %>
                <% end %>
            </div>
        </nav>
    </div>
</header>
```

**`app/views/layouts/_footer.html.erb`**
```html
<footer class="border-t border-white/10 py-16 px-4 mt-20">
    <div class="max-w-6xl mx-auto text-center">
        <h2 class="text-3xl font-display font-bold mb-4 gradient-text">VibeVoyage</h2>
        <p class="text-slate-400 mb-8 max-w-md mx-auto">
            We transform your tastes into memorable experiences.
        </p>
        <div class="flex flex-wrap justify-center gap-8 text-sm text-slate-400 mb-8">
            <a href="#" class="hover:text-white transition-colors">About us</a>
            <a href="#" class="hover:text-white transition-colors">How it works</a>
            <a href="#" class="hover:text-white transition-colors">Cities</a>
            <a href="#" class="hover:text-white transition-colors">Privacy</a>
            <a href="#" class="hover:text-white transition-colors">Contact</a>
        </div>
        <p class="text-xs text-slate-600">© <%= Time.now.year %> VibeVoyage. All rights reserved.</p>
    </div>
</footer>
```

#### **3. Implementación de la Vista Principal (`home/index`)**

Esta es la página principal que el usuario ve. Contiene el "lienzo mágico" que se actualizará dinámicamente.

**`app/controllers/home_controller.rb`**
```ruby
class HomeController < ApplicationController
  def index
    # No necesita lógica especial, solo renderiza la vista.
  end
end
```

**`app/views/home/index.html.erb`**
```html
<%# Tarea 3.3: Suscripción al canal de Action Cable para actualizaciones en tiempo real %>
<%= turbo_stream_from "itinerary_channel:#{current_user&.id || session.id}" %>

<div class="relative">
    <!-- Indicador de Scroll (sería buena idea moverlo al layout si se usa en más páginas) -->
    <%= render 'shared/scroll_indicator' %>

    <%# El contenedor principal que será actualizado por Turbo Streams %>
    <%= turbo_frame_tag "magic_canvas" do %>
        <%= render 'itineraries/hero_form' %>
    <% end %>
</div>
```

#### **4. Parciales para el Flujo de Interacción**

Estos parciales representan los diferentes estados de la UI: el formulario inicial, el estado de "pensando", y los resultados.

**`app/views/itineraries/_hero_form.html.erb`**
```html
<section class="min-h-screen flex items-center justify-center hero-pattern relative overflow-hidden">
    <!-- ... (código de los elementos flotantes de fondo) ... -->
    
    <div class="container mx-auto px-4 pt-20 pb-20">
        <div class="text-center max-w-6xl mx-auto">
            <!-- ... (código del título y la descripción del Héroe) ... -->
            
            <%= form_with url: itineraries_path, data: { turbo_frame: "magic_canvas" } do |form| %>
                <div class="glass-card glass-strong p-8 max-w-3xl mx-auto relative fade-in-up" style="animation-delay: 0.6s;">
                    <!-- ... (código del ícono de chat y el label) ... -->
                    
                    <%= form.text_area :user_vibe, 
                        rows: 4, 
                        class: "w-full p-6 text-lg bg-black/30 border-2 border-white/10 focus:border-terracotta/50 focus:ring-0 resize-none rounded-2xl text-white placeholder-slate-400 transition-all duration-300",
                        placeholder: "Ej: Un día tranquilo en Madrid, con un toque de cine clásico, buena lectura y tapas auténticas..." %>
                    
                    <!-- ... (código de los 3 badges: Local Experiences, AI Curation, etc.) ... -->

                    <%= form.button class: "mt-6 w-full font-bold py-5 px-8 rounded-2xl ... (resto de clases)" do %>
                        <!-- ... (código del SVG y texto del botón "Curar mi Aventura") ... -->
                        Curate my Adventure
                    <% end %>
                </div>
            <% end %>
        </div>
    </div>
</section>
```

**`app/views/itineraries/create.turbo_stream.erb`** (La respuesta del controlador)
```erb
<%# Tarea 2.4: El controlador responde con este Turbo Stream para reemplazar el formulario %>
<%= turbo_stream.replace "magic_canvas" do %>
  <%= render 'itineraries/processing_state' %>
<% end %>
```

**`app/views/itineraries/_processing_state.html.erb`**
```html
<section class="py-20 px-4 min-h-screen flex items-center justify-center" id="processing-section">
    <div class="max-w-4xl mx-auto">
        <div class="glass-card glass-strong p-8 text-center relative overflow-hidden">
            <!-- ... (código completo de la sección "AI Processing" de ui2.html) ... -->
            <h3 class="text-3xl md:text-4xl font-display font-bold text-white mb-4">Analyzing your cultural essence...</h3>
            <!-- ... (resto del HTML de esta sección) ... -->
        </div>
    </div>
</section>
```

**`app/views/itineraries/_results.html.erb`** (Este se renderizará a través de Action Cable)```html
<%= turbo_stream.replace "magic_canvas" do %>
  <section class="py-20 px-4" id="timeline-section">
      <div class="max-w-6xl mx-auto">
          <!-- ... (código completo de la sección "Timeline" y "Journey Summary" de ui2.html) ... -->
          <h2 class="text-4xl md:text-5xl lg:text-6xl font-display font-bold mb-6">
              Your Bohemian Saturday in <span class="gradient-text"><%= @itinerary.location %></span>
          </h2>
          <!-- ... (resto del HTML con loops para renderizar las paradas @itinerary.itinerary_stops) ... -->
      </div>
  </section>
<% end %>
```

#### **5. Lógica del Controlador y Job**

**`app/controllers/itineraries_controller.rb`**
```ruby
class ItinerariesController < ApplicationController
  before_action :authenticate_user! # Asegurarse de que el usuario esté logueado

  def create
    user_vibe = params[:user_vibe]
    
    # Tarea 2.3: Encolar el Job
    VibeCurationJob.perform_later(current_user.id, user_vibe, session.id)

    # Tarea 2.4: Responder con Turbo Stream para mostrar el estado de "procesando"
    respond_to do |format|
      format.turbo_stream
    end
  end
end
```

**`app/jobs/vibe_curation_job.rb`**
```ruby
class VibeCurationJob < ApplicationJob
  queue_as :default

  def perform(user_id, user_vibe, session_id)
    # 1. Cargar el workflow de `rdawn`
    workflow_data = VibeVoyageWorkflow.definition # Asumiendo que el workflow está en una clase
    
    # 2. Preparar el input inicial para el workflow
    initial_input = {
      user_id: user_id,
      user_vibe: user_vibe,
      session_id: session_id # Para el canal de Action Cable
    }

    # 3. Ejecutar el workflow (el workflow mismo se encargará de las actualizaciones de UI)
    # El workflow debe tener una tarea final que use `ActionCableTool`
    # para renderizar `itineraries/_results.html.erb`
    result = Rdawn::Rails::WorkflowJob.run_workflow_now(
      workflow_data: workflow_data,
      initial_input: initial_input
    )

    # 4. (Tarea 5.1) Si el workflow fue exitoso, guardar los resultados
    if result.status == :completed
      final_itinerary_data = result.variables[:final_itinerary] # Asumiendo que el workflow guarda aquí el resultado
      user = User.find(user_id)
      
      # Lógica para crear los registros Itinerary y ItineraryStop en la BD...
    end
  end
end
```

Con este código, has implementado la estructura fundamental de la aplicación, conectando el frontend visualmente rico con el potente motor de backend de `rdawn`, todo orquestado a través de Hotwire para una experiencia de usuario fluida y en tiempo real. Los siguientes pasos serían rellenar los detalles de los prompts y la lógica del handler `NarrativeBuilder`, pero la arquitectura principal ya está en su lugar.
