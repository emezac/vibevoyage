¡Excelente iniciativa! Recrear el framework "Dawn" en Ruby como una gema ("rdawn") es un proyecto ambicioso y muy interesante que puede aportar un gran valor al ecosistema Ruby, que históricamente ha tenido menos herramientas de este tipo en comparación con Python.

Basado en el análisis completo del `repomix-output.xml` proporcionado, he extraído la filosofía, arquitectura y características clave de "Dawn" para plasmarlas en un plan de desarrollo para "rdawn".

Aquí tienes los dos entregables que solicitaste:

1.  **Un Plan de Desarrollo de Proyecto (PRD) detallado** para "rdawn".
2.  **Una TODO list súper detallada y granulada** para la ejecución del proyecto.

---

### **1. Plan de Desarrollo de Proyecto (PRD): rdawn**

**Versión:** 1.0  
**Fecha:** 24 de Octubre de 2025  
**Autor:** (Tu Nombre/Equipo)

#### **1. Resumen Ejecutivo**

`rdawn` (Ruby-Dawn) será un framework de código abierto para Ruby, diseñado para la construcción de agentes de Inteligencia Artificial (IA) robustos y modulares. Su principal diferenciador será un **Sistema de Gestión de Flujo de Trabajo (WMS)** explícito y dinámico, inspirado en el framework "Dawn" de Python. `rdawn` permitirá a los desarrolladores de Ruby orquestar tareas complejas, integrar herramientas externas (APIs, bases de datos), gestionar el contexto y la memoria a largo plazo (LTM) a través de Vector Stores, y construir agentes adaptables que puedan planificar y reaccionar a resultados intermedios. El proyecto será distribuido como una gema (`gem`) para facilitar su integración en aplicaciones Ruby on Rails y otros proyectos Ruby.

#### **2. Motivación y Problema a Resolver**

El ecosistema de IA en Ruby, aunque creciente, carece de un framework estandarizado y de alto nivel para la creación de agentes complejos. Los desarrolladores a menudo deben construir la lógica de orquestación, gestión de estado y encadenamiento de herramientas desde cero. `rdawn` busca resolver esto proporcionando una solución estructurada que ofrece:

*   **Abstracción de la Complejidad:** Oculta la lógica de bajo nivel de la gestión de estado, retries y flujo condicional.
*   **Fiabilidad y Depuración:** Un WMS explícito hace que el comportamiento del agente sea más predecible, depurable y mantenible en comparación con los enfoques de "caja negra".
*   **Extensibilidad:** Un sistema de registro de herramientas (`ToolRegistry`) y manejadores (`HandlerRegistry`) permitirá una fácil expansión de las capacidades del agente.
*   **Capacidades Modernas:** Integra de forma nativa conceptos de vanguardia como RAG (Retrieval-Augmented Generation) a través de Vector Stores y la interoperabilidad mediante protocolos como MCP.

#### **3. Metas y Objetivos**

*   **Meta Principal:** Convertir a `rdawn` en el framework de referencia en Ruby para construir agentes de IA complejos, fiables y contextualmente conscientes.

*   **Objetivos Clave (para v1.0):**
    1.  **Implementar el WMS Central:** Crear las clases `Agent`, `Workflow` y `Task` en Ruby, que son el corazón del sistema.
    2.  **Desarrollar un Motor de Ejecución:** Construir un `WorkflowEngine` que pueda ejecutar flujos de trabajo secuenciales y condicionales, manejando dependencias y resolución de variables.
    3.  **Integrar Herramientas y LLMs:** Proveer una `LLMInterface` para interactuar con APIs como OpenAI y un `ToolRegistry` para registrar y ejecutar código Ruby personalizado.
    4.  **Habilitar Conciencia de Contexto (RAG):** Integrar herramientas para la gestión de Vector Stores (crear, subir archivos, buscar) para permitir a los agentes acceder a bases de conocimiento externas.
    5.  **Empaquetar como Gema:** Asegurar que el framework sea fácilmente instalable (`gem install rdawn`) y utilizable en cualquier proyecto Ruby.

#### **4. Alcance del Proyecto (Versión 1.0)**

| Incluido en v1.0 | Excluido (Consideraciones Futuras) |
| :--- | :--- |
| **Clases Core:** `Agent`, `Workflow`, `Task`, `DirectHandlerTask`. | Orquestación compleja multi-agente. |
| **Motor de Ejecución:** Soporte para flujos secuenciales y condicionales. | Ejecución paralela de tareas (se implementará en v1.1). |
| **Interfaz LLM:** Conector inicial para OpenAI (`ruby-openai` gem). | Soporte para otros proveedores de LLM (Anthropic, Google). |
| **Sistema de Herramientas:** `ToolRegistry` y `HandlerRegistry`. | Un mercado o ecosistema de plugins de terceros. |
| **Resolución de Variables:** Soporte para sintaxis `#{...}` para pasar datos entre tareas, incluyendo acceso a hashes anidados. | Generación de código Ruby dinámico por el agente. |
| **Herramientas de Vector Store:** Funcionalidad para crear, eliminar y añadir archivos/texto a Vector Stores de OpenAI. | Integración con bases de datos vectoriales locales o auto-alojadas. |
| **Gestión de Errores:** Propagación de errores entre tareas. | Optimización de flujos de trabajo basada en Machine Learning. |
| **Configuración:** Carga desde archivos YAML y variables de entorno. | Una interfaz gráfica de usuario (GUI) para diseñar workflows. |
| **Documentación y Testing:** Documentación completa de la API (YARD) y suite de tests (RSpec). | Soporte para el protocolo MCP (planificado para v1.2). |

#### **5. Características Clave Detalladas**

*   **`rdawn::Workflow`**: Un objeto que contendrá una colección de `Task`s. Gestionará el orden de ejecución, las dependencias y el estado general (`:pending`, `:running`, `:completed`, `:failed`).
*   **`rdawn::Task`**: La unidad de trabajo. Un objeto con atributos como `:task_id`, `:name`, `:status`, `:input_data`, `:output_data`, `:tool_name`, `:is_llm_task`, y `:next_task_id_on_success`/`:failure`.
*   **`rdawn::DirectHandlerTask`**: Una subclase de `Task` para ejecutar bloques de código Ruby (`Proc` o `lambda`) directamente, ideal para lógica de transformación o validación específica del workflow.
*   **`rdawn::WorkflowEngine`**: El orquestador.
    *   **Resolución de Variables:** Antes de ejecutar una tarea, procesará su `:input_data` para sustituir placeholders como `#{task1.output_data.result.user.name}` con los valores correspondientes del estado del workflow.
    *   **Lógica Condicional:** Evaluará el campo `:condition` de una tarea para decidir la ruta de ejecución.
*   **`rdawn::LLMInterface`**: Abstraerá las llamadas a la gema `ruby-openai`, manejando la construcción de prompts y la extracción de respuestas y llamadas a herramientas.
*   **`rdawn::ToolRegistry`**: Un registro central donde los desarrolladores pueden registrar sus propias herramientas (módulos o clases de Ruby con un método `execute`).
*   **Herramientas de Vector Store**: Módulos que encapsulan la lógica para interactuar con la API de Vector Stores de OpenAI, permitiendo RAG.
*   **Generación Dinámica de Workflows (JSON):** Se definirá un esquema JSON que represente un workflow de `rdawn`. El framework incluirá un parser para cargar un workflow desde este JSON, permitiendo que los flujos de trabajo sean generados, almacenados y modificados como datos.

#### **6. Enfoque Técnico**

*   **Lenguaje:** Ruby (>= 3.0).
*   **Empaquetado:** RubyGems.
*   **Dependencias:** `bundler`, `rake`, `rspec`, `ruby-openai`, `httpx` (o `faraday`), `activesupport` (para utilidades como `HashWithIndifferentAccess`), `zeitwerk` (para carga de archivos).
*   **Validación de Datos:** Se explorará el uso de `dry-struct` o `dry-validation` para la validación de hashes de entrada/salida.
*   **Testing:** RSpec será el framework de pruebas principal.

#### **7. Riesgos y Mitigación**

*   **Ecosistema de IA en Ruby:** Menos maduro que el de Python. **Mitigación:** Depender de la gema oficial de OpenAI y construir abstracciones sólidas para facilitar la integración de futuras herramientas.
*   **Performance en Concurrencia:** El GVL de Ruby puede ser una limitación para tareas intensivas en CPU. **Mitigación:** Diseñar el motor para ser compatible con I/O no bloqueante (usando `async` o `Fibers`) para las llamadas a APIs, que es el caso de uso principal.
*   **Complejidad de la Resolución de Variables:** Implementar un resolver robusto y seguro es complejo. **Mitigación:** Empezar con un subconjunto de funcionalidades (acceso a hashes anidados) y expandir gradualmente, con una suite de tests muy completa.

---

### **2. TODO List Detallada para `rdawn`**

Esta lista de tareas está diseñada para ser ejecutada en fases, asegurando que se construya una base sólida antes de añadir funcionalidades más complejas.

#### **🚀 Fase 1: Estructura del Proyecto y Modelos Core (2 Semanas)**

*   **1.1: Configuración de la Gema**
    *   `[ ]` Crear la estructura de directorios de la gema: `rdawn/`, `rdawn/lib/`, `rdawn/lib/rdawn`, `rdawn/spec/`.
    *   `[ ]` Crear el archivo `rdawn.gemspec` con información básica (nombre, versión, autor, dependencias).
    *   `[ ]` Configurar `Gemfile` con `bundler` para gestionar las dependencias de desarrollo (`rspec`, `rake`).
    *   `[ ]` Crear un `Rakefile` básico con tareas para testear y construir la gema.
    *   `[ ]` Configurar `RSpec` con `spec/spec_helper.rb`.
    *   `[ ]` Configurar un `README.md` inicial.
    *   `[ ]` Configurar un linter como `RuboCop` (`.rubocop.yml`).

*   **1.2: Implementación de Modelos de Datos**
    *   `[ ]` **`rdawn/lib/rdawn/task.rb`**:
        *   `[ ]` Crear la clase `Task`.
        *   `[ ]` Definir atributos: `@task_id`, `@name`, `@status`, `@input_data`, `@output_data`, `@tool_name`, `@is_llm_task`.
        *   `[ ]` Definir atributos de control: `@next_task_id_on_success`, `@next_task_id_on_failure`, `@condition`.
        *   `[ ]` Implementar métodos de gestión de estado: `mark_complete`, `mark_failed`, `set_output`.
        *   `[ ]` Implementar `to_h` para serialización.
    *   `[ ]` **`rdawn/spec/rdawn/task_spec.rb`**:
        *   `[ ]` Escribir tests para la inicialización de `Task`.
        *   `[ ]` Escribir tests para los métodos de estado.
    *   `[ ]` **`rdawn/lib/rdawn/workflow.rb`**:
        *   `[ ]` Crear la clase `Workflow`.
        *   `[ ]` Definir atributos: `@workflow_id`, `@name`, `@status`, `@tasks` (un Hash).
        *   `[ ]` Implementar `add_task(task)`.
        *   `[ ]` Implementar `get_task(task_id)`.
    *   `[ ]` **`rdawn/spec/rdawn/workflow_spec.rb`**:
        *   `[ ]` Escribir tests para `add_task` y `get_task`.

#### **⚙️ Fase 2: Motor de Ejecución y Herramientas (3 Semanas)**

*   **2.1: `LLMInterface` y `ToolRegistry`**
    *   `[ ]` **`rdawn/lib/rdawn/llm_interface.rb`**:
        *   `[ ]` Crear clase `LLMInterface`.
        *   `[ ]` Implementar `execute_llm_call(prompt)` usando la gema `ruby-openai`.
        *   `[ ]` Añadir manejo de errores para las llamadas a la API.
    *   `[ ]` **`rdawn/lib/rdawn/tool_registry.rb`**:
        *   `[ ]` Crear clase `ToolRegistry`.
        *   `[ ]` Implementar `register(name, tool_object)` y `execute(name, input_data)`.
    *   `[ ]` **`rdawn/spec/rdawn/tool_registry_spec.rb`**:
        *   `[ ]` Escribir tests para registrar y ejecutar una herramienta mock.

*   **2.2: Motor de Ejecución Secuencial**
    *   `[ ]` **`rdawn/lib/rdawn/workflow_engine.rb`**:
        *   `[ ]` Crear clase `WorkflowEngine`.
        *   `[ ]` Implementar el bucle principal de ejecución en el método `run`.
        *   `[ ]` Añadir lógica para iterar sobre las tareas en orden.
        *   `[ ]` Despachar a `LLMInterface` si `task.is_llm_task` es `true`.
        *   `[ ]` Despachar a `ToolRegistry` si `task.tool_name` está presente.
    *   `[ ]` **`rdawn/spec/rdawn/workflow_engine_spec.rb`**:
        *   `[ ]` Escribir test para un workflow secuencial simple.

*   **2.3: Resolución de Variables y Flujo Condicional**
    *   `[ ]` **`rdawn/lib/rdawn/variable_resolver.rb`**:
        *   `[ ]` Implementar módulo o clase `VariableResolver`.
        *   `[ ]` Crear método `resolve(input_data, context)` que sustituya `#{...}`.
        *   `[ ]` Soportar acceso a hashes anidados (ej. `#{task1.output.user.name}`).
    *   `[ ]` **Actualizar `WorkflowEngine`**:
        *   `[ ]` Antes de ejecutar una tarea, llamar a `VariableResolver.resolve`.
        *   `[ ]` Después de una tarea, añadir su `output_data` al contexto.
        *   `[ ]` Implementar la lógica para `next_task_id_on_success/failure` y `:condition`.
    *   `[ ]` **`rdawn/spec/rdawn/variable_resolver_spec.rb`**:
        *   `[ ]` Escribir tests para diferentes casos de resolución de variables.
    *   `[ ]` **`rdawn/spec/rdawn/workflow_engine_spec.rb`**:
        *   `[ ]` Añadir tests para workflows con dependencias de datos y condicionales.

#### **🧩 Fase 3: Funcionalidades Avanzadas (3 Semanas)**

*   **3.1: `DirectHandlerTask` y `HandlerRegistry`**
    *   `[ ]` **`rdawn/lib/rdawn/task.rb`**: Crear la subclase `DirectHandlerTask`.
    *   `[ ]` **`rdawn/lib/rdawn/handler_registry.rb`**: Implementar el registro de `Procs` o `lambdas`.
    *   `[ ]` **Actualizar `WorkflowEngine`**: Añadir lógica para ejecutar `DirectHandlerTask`s.

*   **3.2: Herramientas de Vector Store (RAG)**
    *   `[ ]` **`rdawn/lib/rdawn/tools/vector_store_tools.rb`**:
        *   `[ ]` Crear un módulo para las herramientas de VS.
        *   `[ ]` Implementar `create_vector_store`.
        *   `[ ]` Implementar `upload_file_to_vector_store` (incluyendo polling).
        *   `[ ]` Implementar `save_text_to_vector_store`.
    *   `[ ]` **Actualizar `LLMInterface`**:
        *   `[ ]` Añadir soporte para el parámetro `file_search` en la llamada a la API de OpenAI.
    *   `[ ]` **`spec/rdawn/tools/vector_store_tools_spec.rb`**: Escribir tests para las nuevas herramientas.

*   **3.3: Error Handling y Configuración**
    *   `[ ]` **`rdawn/lib/rdawn/errors.rb`**: Crear clases de error personalizadas (`ConfigurationError`, `TaskExecutionError`).
    *   `[ ]` **`rdawn/lib/rdawn/config.rb`**: Implementar un sistema de configuración que lea un archivo `rdawn.yml` y variables de entorno.

#### **📦 Fase 4: Empaquetado y Documentación (2 Semanas)**

*   **4.1: Documentación**
    *   `[ ]` Escribir la documentación principal en el `README.md`.
    *   `[ ]` Usar YARD para generar documentación de la API a partir de comentarios de código.
    *   `[ ]` Crear 1-2 ejemplos completos en el directorio `examples/`.

*   **4.2: Finalización de la Gema**
    *   `[ ]` Revisar y finalizar el `rdawn.gemspec`.
    *   `[ ]` Crear una tarea en `Rakefile` para construir la gema (`rake build`).
    *   `[ ]` Probar la instalación local de la gema construida.

*   **4.3: Publicación (Opcional)**
    *   `[ ]` Crear una tarea en `Rakefile` para publicar la gema en RubyGems.org (`rake release`).
    *   `[ ]` Publicar la versión 0.1.0 de la gema `rdawn`.

