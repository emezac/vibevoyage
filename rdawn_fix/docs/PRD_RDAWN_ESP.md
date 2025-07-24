### **Documento de Requisitos de Producto (PRD): `rdawn`**

**Versión:** 1.0
**Fecha:** 16 de julio de 2025
**Estado:** Borrador

#### **1. Resumen Ejecutivo**

`rdawn` es un framework de código abierto para Ruby, construido sobre Ruby on Rails 8.0, diseñado para la creación de **agentes de IA robustos y nativos de la web**. A diferencia de los frameworks de agentes que operan como servicios externos, `rdawn` se concibe como el **sistema nervioso central de una aplicación SaaS**, permitiendo a los desarrolladores construir capacidades de IA que están profundamente integradas con los modelos de datos, la lógica de negocio y el contexto de usuario de la aplicación. Su diferenciador clave es un Sistema de Gestión de Flujo de Trabajo (WMS) explícito que orquesta tareas complejas, aprovechando todo el poder del ecosistema de Rails, desde Active Record hasta Active Job y Action Cable, para crear una nueva categoría de **SaaS Agéntico**.

#### **2. Visión y Motivación**

La narrativa actual de que los "agentes de IA reemplazarán al SaaS" es una simplificación excesiva. La verdadera transformación no es el reemplazo, sino la **fusión**: el SaaS se volverá agéntico. Las aplicaciones web pasarán de ser herramientas pasivas que responden a clics, a ser **socios activos y proactivos** que entienden los objetivos del usuario y trabajan de forma autónoma para alcanzarlos.

`rdawn` nace para ser el catalizador de esta transformación dentro del ecosistema Ruby on Rails, un entorno ideal para construir aplicaciones de negocio complejas y centradas en los datos. La visión de `rdawn` es permitir a los desarrolladores de Rails construir características de IA que no se sientan como un añadido, sino como una parte fundamental, inteligente y nativa del producto.

#### **3. El Problema a Resolver**

Actualmente, los desarrolladores de Rails que desean integrar IA avanzada enfrentan una disyuntiva:

1.  **Construir desde cero:** Crear la lógica de orquestación, gestión de estado y encadenamiento de herramientas es complejo y propenso a errores.
2.  **Usar servicios externos (Python):** Integrar agentes basados en Python requiere construir y mantener APIs internas, gestionar la comunicación de red, duplicar la lógica de negocio y enfrentar enormes desafíos de seguridad y contexto de datos. El agente externo es un "ciudadano de segunda clase" que no entiende la riqueza del ecosistema Rails.

`rdawn` resuelve este problema proporcionando una solución **nativa de Rails** que elimina esta fricción, permitiendo a los agentes operar con un conocimiento y una capacidad de acción sin precedentes dentro de la propia aplicación.

#### **4. Metas y Objetivos (Versión 1.0)**

*   **Meta Principal:** Convertir a `rdawn` en el framework de referencia para construir copilotos y agentes de IA en aplicaciones SaaS de Ruby on Rails.

*   **Objetivos Clave:**
    1.  **Implementar el WMS Central en Ruby:** Crear las clases `Rdawn::Agent`, `Rdawn::Workflow` y `Rdawn::Task` (incluyendo `DirectHandlerTask`), que son el corazón del sistema de orquestación.
    2.  **Integración Profunda con Active Record:** El motor de resolución de variables y los `DirectHandlerTask` deben poder interactuar de forma nativa con los modelos de Active Record (`User.find`, `project.tasks.create!`).
    3.  **Integración con Active Job:** Permitir que las tareas de `rdawn` de larga duración se puedan ejecutar en segundo plano usando la infraestructura de Active Job (con backends como Sidekiq o GoodJob).
    4.  **Sistema de Herramientas Extensible:** Proveer un `Rdawn::ToolRegistry` donde los desarrolladores puedan registrar fácilmente sus propias herramientas, que pueden ser simples módulos de Ruby o clases de servicio.
    5.  **Integración con OpenAI File Search:** Implementar las capacidades de RAG (Retrieval-Augmented Generation) permitiendo a las tareas LLM utilizar la herramienta `file_search` de OpenAI para consultar Vector Stores.
    6.  **Empaquetado como Gema:** Asegurar que el framework sea una gema (`gem`) de Rails, fácilmente instalable y configurable a través de un inicializador (`config/initializers/rdawn.rb`).

#### **5. Filosofía de Diseño: El "Socio Nativo de Rails"**

La ventaja competitiva fundamental de `rdawn` no reside en las capacidades del LLM en sí, sino en su **simbiosis con el framework Ruby on Rails**. Un agente `rdawn` no es un servicio externo; es un ciudadano de primera clase de la aplicación. Esta filosofía se basa en los siguientes pilares:

1.  **Acceso Nativo al Modelo de Datos (Active Record):** Un agente `rdawn` no necesita una API para leer o escribir en la base de datos. Puede ejecutar `Project.find(1).tasks.late` directamente. Esto es más rápido, más seguro y aprovecha toda la lógica de negocio existente (asociaciones, validaciones, scopes, callbacks).
2.  **Contexto de Usuario y Seguridad Integrados (Devise & Pundit):** El agente opera en nombre de un `current_user`. Antes de ejecutar una acción, puede y debe verificar los permisos con el sistema de autorización de la aplicación (ej. `policy(task).update?`). El agente nunca podrá hacer algo que el usuario no tendría permitido.
3.  **Aprovechamiento del Ecosistema de Gemas Web:**
    *   **Jobs en Segundo Plano (Active Job):** Tareas largas como "Genera un informe de 10 páginas" se convierten en un simple `RiskAnalysisAgentJob.perform_later(project)`.
    *   **Notificaciones (Action Mailer / Noticed):** El agente puede enviar correos electrónicos o crear notificaciones de forma nativa.
    *   **Interactividad en Tiempo Real (Action Cable & Turbo):** Un agente puede finalizar su trabajo y enviar los resultados directamente al navegador del usuario a través de un `Turbo Stream`, actualizando la UI sin necesidad de recargar la página. La experiencia de usuario es espectacular.
4.  **Arquitectura de "Monolito Majestuoso" Simplificada:** Elimina la necesidad de construir, versionar y mantener APIs internas solo para que el agente se comunique con la aplicación. La lógica del agente vive en el mismo codebase, simplificando el desarrollo, las pruebas y la refactorización.

#### **6. Arquitectura y Componentes Fundamentales**

`rdawn` adaptará la arquitectura de "Dawn" al paradigma de Ruby on Rails:

*   **`Rdawn::Agent`**: La entidad que ejecuta un `Workflow`. Configurado con un ID, nombre y una `Rdawn::LLMInterface`. Podrá asociarse a un `current_user`.
*   **`Rdawn::Workflow`**: El objeto que define la lógica de orquestación. Contiene una colección de `Rdawn::Task`.
*   **`Rdawn::Task`**: La unidad de trabajo.
    *   **Atributos Clave:** `task_id`, `name`, `status`, `input_data` (con soporte para variables `${...}`), `is_llm_task`, `tool_name`, `next_task_id_on_success`/`failure`, `condition`.
    *   **Parámetros de File Search:** `use_file_search`, `file_search_vector_store_ids`.
    *   **Subclases:**
        *   **`Rdawn::DirectHandlerTask`**: Ejecuta directamente un bloque de código Ruby (`Proc` o `lambda`), o una clase de servicio de Rails. Es la piedra angular para la integración con Active Record y la lógica de negocio.
*   **`Rdawn::WorkflowEngine` (WMS):** El orquestador.
    *   **Resolución de Variables:** Resuelve las referencias `${...}` usando el contexto del workflow.
    *   **Ejecución de Tareas:** Selecciona la estrategia de ejecución (LLM, Tool, DirectHandler).
    *   **Integración con Active Job:** Capaz de encolar la ejecución de una `Task` en un job para procesamiento asíncrono.
*   **`Rdawn::ToolRegistry`**: Registro para herramientas reutilizables (módulos o clases de Ruby).
*   **Integración con Rails:**
    *   **Generadores:** `rails g rdawn:workflow my_workflow` para crear plantillas de workflows.
    *   **Inicializador:** `config/initializers/rdawn.rb` para configurar la gema (ej. API keys del LLM, configuración por defecto).
    *   **Concerns/Mixins:** Módulos que se pueden incluir en modelos o controladores para facilitar la interacción con agentes `rdawn`.

#### **7. Características Clave (v1.0)**

| Característica | Descripción |
| :--- | :--- |
| **Motor de Workflow** | Ejecución de flujos de trabajo secuenciales y condicionales. |
| **`DirectHandlerTask`** | Ejecución de código Ruby y lógica de Rails directamente. |
| **Integración Active Record** | Capacidad de los handlers para consultar y manipular modelos. |
| **Integración Active Job** | `Rdawn::Agent.run_later(workflow, initial_input)` para ejecución en segundo plano. |
| **Interfaz LLM (OpenAI)** | Conector para `client.chat.completions.create` usando la gema `ruby-openai`. |
| **File Search (RAG)** | Soporte para `use_file_search` y `vector_store_ids` en tareas LLM. |
| **Sistema de Herramientas** | `Rdawn::ToolRegistry` para registrar y ejecutar herramientas. |
| **Herramientas de Vector Store** | Incluirá herramientas básicas para gestionar Vector Stores de OpenAI (`vector_store_create`, `upload_file_to_vector_store`, etc.). |
| **Resolución de Variables** | Soporte para sintaxis `${...}` para pasar datos entre tareas, incluyendo acceso a hashes anidados. |
| **Configuración** | Carga de configuración desde el inicializador de Rails y variables de entorno. |
| **Documentación y Testing** | Documentación completa y un arnés de pruebas (`TestHarness`) para facilitar los tests de workflows. |

#### **8. Casos de Uso Ideales y Aplicaciones SaaS**

`rdawn` está optimizado para construir características de IA que son el núcleo de la propuesta de valor de un SaaS.

1.  **Copiloto de CRM / Gestión de Proyectos (Ej. Basecamp/Jira en Rails):**
    *   **Por qué es ideal:** Un agente `rdawn` puede consultar `Project.find_by_name(...)`, crear `project.tasks.create(...)`, y verificar permisos con Pundit. La experiencia de usuario se puede hacer en tiempo real con Turbo Streams. Este es el arquetipo de la "killer app" para `rdawn`.
2.  **CRM para Abogados (Ej. Clio/MyCase en Rails):**
    *   **Por qué es ideal:** Los conceptos de **Confianza, Contexto y Control** son primordiales. Un agente `rdawn` vive dentro de la aplicación, heredando la seguridad de Devise/Pundit (confianza), accediendo a los modelos `Case` y `Document` (contexto), y siguiendo flujos de trabajo legales estrictos (control).
3.  **Plataforma de E-commerce (Ej. Solidus/Spree):**
    *   **Por qué es ideal:** Un agente `rdawn` puede actuar como un "personal shopper" consultando `Spree::Product.where(...)`, o como un gestor de inventario que crea alertas (`ActionMailer`) cuando `Spree::StockItem.count_on_hand` baja de un umbral, todo de forma nativa.

#### **9. Enfoque Técnico y Dependencias**

*   **Lenguaje:** Ruby 3.4.5
*   **Framework:** Ruby on Rails 8.0
*   **Dependencias Clave (Gemas):**
    *   `activesupport`, `activejob`: Para utilidades y trabajos en segundo plano.
    *   `ruby-openai`: Para la interfaz con el LLM.
    *   `httpx` o `faraday`: Para llamadas a APIs en herramientas.
    *   `zeitwerk`: Para la carga de archivos de la gema.
*   **Testing:** RSpec será el framework de pruebas principal.

#### **10. Experiencia del Desarrollador (DevEx)**

*   **Instalación Sencilla:** `bundle add rdawn` y `rails g rdawn:install`.
*   **Generadores de Código:** `rails g rdawn:workflow <nombre>` y `rails g rdawn:tool <nombre>` para crear plantillas.
*   **Configuración Centralizada:** Un único archivo `config/initializers/rdawn.rb`.
*   **Documentación Clara:** Guías detalladas sobre cómo integrar `rdawn` con componentes de Rails como Active Job y Pundit.
*   **Arnés de Pruebas (`TestHarness`):** Una utilidad para facilitar la escritura de tests para workflows, permitiendo mockear fácilmente las respuestas de LLMs y herramientas.

#### **11. Riesgos y Mitigación**

*   **Riesgo:** El ecosistema de IA en Ruby es menos maduro que en Python.
    *   **Mitigación:** Construir sobre la gema oficial de `ruby-openai` y diseñar una `LLMInterface` abstracta que permita añadir otros proveedores en el futuro. El valor no está en las librerías de ML, sino en la integración con Rails.
*   **Riesgo:** El rendimiento concurrente puede ser una preocupación (Global VM Lock).
    *   **Mitigación:** El caso de uso principal (interacción con APIs externas) es intensivo en I/O, no en CPU. La integración nativa con Active Job para tareas largas es la solución idiomática y recomendada.
*   **Riesgo:** Mantener la compatibilidad con futuras versiones de Rails.
    *   **Mitigación:** Adherirse a las APIs públicas de Rails y mantener una suite de pruebas robusta que se ejecute contra diferentes versiones de Rails.

#### **12. Métricas de Éxito**

*   **Adopción:** Número de aplicaciones Rails que integran `rdawn`.
*   **Facilidad de Uso:** Un desarrollador de Rails puede construir un copiloto básico en menos de un día.
*   **Rendimiento:** Las tareas en segundo plano se integran sin problemas con Sidekiq/GoodJob.
*   **Comunidad:** Contribuciones externas al proyecto, creación de herramientas `rdawn` de terceros.

#### **13. Hoja de Ruta Futura (Post v1.0)**

*   **Integración con Action Cable:** Herramientas y guías para enviar resultados de agentes a la UI en tiempo real.
*   **Soporte para Múltiples LLMs:** Añadir conectores para otros proveedores como Anthropic o Google.
*   **Generación Dinámica de Workflows (JSON):** Capacidad de que un agente genere la definición de otro workflow como un objeto JSON, para luego ser interpretado y ejecutado.
*   **Integración MCP (Model Context Protocol):** Implementar un `MCPTool` para interactuar con herramientas externas estandarizadas.
*   **Optimización Basada en ML:** (A muy largo plazo) Analizar ejecuciones de workflows para sugerir optimizaciones.

---
