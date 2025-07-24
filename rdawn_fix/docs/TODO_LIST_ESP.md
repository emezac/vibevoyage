

---
# Este plan de acción está diseñado para construir `rdawn` como una gema de Ruby pura y potente, con una integración opcional pero profunda con Ruby on Rails, asegurando que el núcleo del framework permanezca agnóstico.

### **TODO List Detallada: Construcción del Framework `rdawn` como Gema de Ruby**

**Objetivo del Sprint:** Crear la versión 0.1.0 de la gema `rdawn`, estableciendo las bases del Workflow Management System (WMS), la integración con LLMs a través de `raix`/`open_router`, y la estructura para la integración opcional con Rails.

**Leyenda de Prioridades:**
*   🔴 **Crítico:** Fundamental para la funcionalidad básica del sprint.
*   🟡 **Importante:** Necesario para una característica completa, pero puede tener soluciones temporales.
*   🟢 **Deseable:** Mejora la calidad o la experiencia del desarrollador; puede posponerse si el tiempo apremia.

---

#### **🚀 Fase 1: Andamiaje del Proyecto y Modelos de Datos Core (Semana 1)**

*   **1.1: Configuración de la Gema (Día 1)**
    *   `[ ]` 🔴 **Crear la estructura de la gema:** Ejecutar `bundle gem rdawn` para generar el esqueleto del proyecto.
    *   `[ ]` 🔴 **Definir el `rdawn.gemspec`:**
        *   Completar metadatos: `name`, `version` ("0.1.0"), `authors`, `summary`, `description`, `license` ("MIT").
        *   Añadir dependencias de runtime: `spec.add_dependency "raix"`, `spec.add_dependency "open_router"`, `spec.add_dependency "activesupport"` (para utilidades como `HashWithIndifferentAccess`), `spec.add_dependency "httpx"` (para herramientas), `spec.add_dependency "zeitwerk"`.
        *   Añadir dependencias de desarrollo: `spec.add_development_dependency "rspec"`, `spec.add_development_dependency "rubocop"`, `spec.add_development_dependency "pry"`.
    *   `[ ]` 🟡 **Configurar RSpec:**
        *   Crear `spec/spec_helper.rb` para la configuración de las pruebas.
        *   Crear el archivo `.rspec` en la raíz con opciones por defecto (`--format documentation`).
    *   `[ ]` 🟡 **Configurar RuboCop:**
        *   Crear `.rubocop.yml` en la raíz con reglas de estilo básicas (p. ej., heredar de `rubocop-rspec`).

*   **1.2: Implementación de Modelos de Datos Core (Días 2-3)**
    *   `[ ]` 🔴 **`lib/rdawn/task.rb`:**
        *   Crear la clase `Rdawn::Task`.
        *   Definir atributos con `attr_accessor`: `task_id`, `name`, `status` (`:pending`, `:running`, etc.), `input_data` (Hash), `output_data` (Hash), `is_llm_task` (Boolean), `tool_name` (String), `max_retries`, `retry_count`.
        *   Definir atributos de control de flujo: `next_task_id_on_success`, `next_task_id_on_failure`, `condition`.
        *   Implementar métodos de estado: `mark_running`, `mark_completed(output)`, `mark_failed(error)`.
        *   Añadir el método `to_h` para serialización.
    *   `[ ]` 🔴 **`spec/rdawn/task_spec.rb`:** Escribir pruebas unitarias para la clase `Task` (inicialización, cambios de estado).
    *   `[ ]` 🔴 **`lib/rdawn/workflow.rb`:**
        *   Crear la clase `Rdawn::Workflow`.
        *   Definir atributos: `workflow_id`, `name`, `status`, `tasks` (Hash para almacenar `Rdawn::Task` por `task_id`), `variables` (Hash).
        *   Implementar `add_task(task)` y `get_task(task_id)`.
    *   `[ ]` 🔴 **`spec/rdawn/workflow_spec.rb`:** Escribir pruebas para `add_task` y `get_task`.
    *   `[ ]` 🔴 **`lib/rdawn/agent.rb`:**
        *   Crear la clase `Rdawn::Agent`.
        *   Definir `initialize(workflow:, llm_interface:)`.
        *   Definir un método `run(initial_input: {})` que instancie y ejecute el `WorkflowEngine`.

*   **1.3: Definición de Errores Personalizados (Día 4)**
    *   `[ ]` 🟡 **`lib/rdawn/errors.rb`:**
        *   Crear un módulo `Rdawn::Errors`.
        *   Definir clases de error personalizadas: `ConfigurationError`, `TaskExecutionError`, `ToolNotFoundError`, `VariableResolutionError`.

*   **1.4: Documentación Inicial (Día 5)**
    *   `[ ]` 🟢 **Actualizar `README.md`:** Añadir una descripción del proyecto, objetivos de la v0.1.0 y un boceto de cómo se usará.
    *   `[ ]` 🟢 **Configurar YARD:** Añadir `yard` al `Gemfile` y configurar una tarea Rake para generar documentación (`rake yard`).

---

#### **⚙️ Fase 2: Motor de Ejecución y Capacidades Básicas (Semana 2)**

*   **2.1: WorkflowEngine - Ejecución Secuencial (Días 6-7)**
    *   `[ ]` 🔴 **`lib/rdawn/workflow_engine.rb`:**
        *   Crear la clase `Rdawn::WorkflowEngine`.
        *   Implementar el bucle principal en el método `run`.
        *   Lógica para encontrar la tarea inicial y seguir la cadena `next_task_id_on_success`.
        *   Implementar un método `execute_task(task)` que por ahora solo simule la ejecución (marcar como completada).
    *   `[ ]` 🔴 **`spec/rdawn/workflow_engine_spec.rb`:** Escribir una prueba para un workflow secuencial simple (2-3 tareas) y verificar que se ejecuten en orden.

*   **2.2: `LLMInterface` y Herramientas (Días 8-9)**
    *   `[ ]` 🔴 **`lib/rdawn/llm_interface.rb`:**
        *   Crear la clase `Rdawn::LLMInterface`.
        *   Implementar `initialize` para recibir configuración (ej. provider, API key).
        *   Implementar `execute_llm_call(prompt:, model_params: {})` que internamente use `Raix.chat` con el provider `OpenRouter`.
    *   `[ ]` 🔴 **`lib/rdawn/tool_registry.rb`:**
        *   Crear la clase `Rdawn::ToolRegistry` (probablemente como un singleton o una instancia única).
        *   Implementar `register(name, tool_object)` y `execute(name, input_data)`.
    *   `[ ]` 🔴 **Actualizar `WorkflowEngine#execute_task`:**
        *   Añadir lógica: si `task.is_llm_task`, llamar a `LLMInterface`.
        *   Si `task.tool_name` está presente, llamar a `ToolRegistry`.
    *   `[ ]` 🟡 **`spec/rdawn/llm_interface_spec.rb`:** Testear la interfaz mockeando la llamada a `Raix.chat`.
    *   `[ ]` 🟡 **`spec/rdawn/tool_registry_spec.rb`:** Testear el registro y la ejecución de una herramienta mock.

*   **2.3: `DirectHandlerTask` (Día 10)**
    *   `[ ]` 🔴 **`lib/rdawn/tasks/direct_handler_task.rb`:**
        *   Crear la subclase `Rdawn::DirectHandlerTask < Rdawn::Task`.
        *   Añadir el atributo `handler` (`Proc` o `lambda`).
    *   `[ ]` 🔴 **Actualizar `WorkflowEngine#execute_task`:** Añadir un `elsif task.is_a?(DirectHandlerTask)` para ejecutar el `handler` directamente.
    *   `[ ]` 🟡 **`spec/rdawn/tasks/direct_handler_task_spec.rb`:** Testear que una tarea de este tipo ejecuta su `Proc` correctamente.

---

#### **🧩 Fase 3: Lógica de Flujo Avanzada y Rails (Opcional) (Semana 3)**

*   **3.1: Resolución de Variables y Condicionales (Días 11-12)**
    *   `[ ]` 🔴 **`lib/rdawn/variable_resolver.rb`:**
        *   Implementar un módulo o clase `VariableResolver`.
        *   Crear un método `resolve(input_data, context)` que sustituya `${...}`. Soportar acceso a hashes anidados (ej. `${task1.output.user.name}`).
    *   `[ ]` 🔴 **Actualizar `WorkflowEngine`:**
        *   Antes de ejecutar una tarea, llamar a `VariableResolver.resolve`.
        *   Después de una tarea, añadir su `output_data` al contexto general del workflow.
        *   Implementar la lógica para `next_task_id_on_success/failure` y evaluar el campo `:condition` si existe.
    *   `[ ]` 🟡 **`spec/rdawn/variable_resolver_spec.rb`:** Testear casos de resolución de variables.
    *   `[ ]` 🟡 **`spec/rdawn/workflow_engine_spec.rb`:** Añadir tests para workflows con dependencias de datos y condicionales.

*   **3.2: Integración Opcional con Rails (Días 13-14)**
    *   `[ ]` 🟡 **Crear `lib/rdawn/rails.rb`:** Este archivo contendrá toda la lógica específica de Rails y solo será cargado por el usuario en un entorno Rails.
    *   `[ ]` 🟢 **Crear un Railtie:** En `rails.rb`, definir un `Rdawn::Railtie` para que se enganche al proceso de inicialización de Rails.
    *   `[ ]` 🟡 **Generador de Instalación:** `lib/generators/rdawn/install_generator.rb`.
        *   Debe crear `config/initializers/rdawn.rb`.
        *   El inicializador configurará la gema (ej. `Rdawn.configure { |config| ... }`).
    *   `[ ]` 🟡 **Integración con Active Job:**
        *   Definir una clase base `Rdawn::ApplicationJob < ActiveJob::Base` en `rdawn/rails.rb`.
        *   Crear un job genérico, ej. `Rdawn::WorkflowJob`, que acepte el nombre de una clase de workflow y los inputs, para luego instanciarla y ejecutarla en `perform`.
    *   `[ ]` 🟢 **Documentar la Integración:** Crear una guía en `docs/RAILS_INTEGRATION.md` explicando cómo usar `rdawn` en una aplicación Rails, incluyendo cómo pasar `current_user` y usar modelos de Active Record en los `DirectHandlerTask`.

*   **3.3: Características Avanzadas (RAG, MCP) (Día 15 - Planificación)**
    *   `[ ]` 🟢 **Planificar herramientas para Vector Store:**
        *   Definir los métodos para las herramientas `vector_store_create`, `upload_file_to_vector_store` (que usará `ruby-openai`).
        *   Añadir `use_file_search` y `vector_store_ids` como parámetros a la `LLMInterface`.
    *   `[ ]` 🟢 **Planificar integración MCP:**
        *   Investigar cómo `ruby_llm` maneja las conexiones MCP (stdio).
        *   Diseñar un `MCPTool` dinámico que pueda ser registrado en `ToolRegistry`.
        *   Identificar los cambios necesarios en `WorkflowEngine` para manejar llamadas `async` a herramientas MCP.

---

#### **📦 Fase 4: Pulido y Empaquetado (Semana 4)**

*   **4.1: Pruebas de Integración (Días 16-17)**
    *   `[ ]` 🟡 Escribir 1 o 2 pruebas de integración completas que ejecuten un workflow de principio a fin, mockeando las llamadas externas (LLM, herramientas).
    *   `[ ]` 🟢 (Si se hizo la integración con Rails) Crear una app de Rails mínima en `spec/dummy` para probar la integración con Active Job.

*   **4.2: Documentación Final (Días 18-19)**
    *   `[ ]` 🔴 **Completar el `README.md`:** Incluir un ejemplo de uso completo, la arquitectura básica y la filosofía del framework.
    *   `[ ]` 🟡 **Generar documentación YARD:** Ejecutar `rake yard` y asegurarse de que la salida sea clara.
    *   `[ ]` 🟡 **Escribir guías en `docs/`:** Crear guías para `WORKFLOWS.md`, `TOOLS.md`, y `DIRECT_HANDLERS.md`.

*   **4.3: Preparación para el Lanzamiento (Día 20)**
    *   `[ ]` 🔴 **Revisar y finalizar el `.gemspec`**.
    *   `[ ]` 🔴 **Construir la gema:** `gem build rdawn.gemspec`.
    *   `[ ]` 🟡 **Probar la gema localmente:** Instalar la gema construida en un proyecto de prueba.
    *   `[ ]` 🟢 **Publicar la gema (v0.1.0):** `gem push rdawn-0.1.0.gem`.

---
