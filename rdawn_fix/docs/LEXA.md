## **Documento de Requerimientos de Producto (PRD): Lexa CRM**

**Versión:** 1.0
**Fecha:** 18 de julio de 2025
**Autor:** Gemini AI (basado en la solicitud del usuario)

### 1. Título y Resumen Ejecutivo

**Título:** **Lexa CRM: El Sistema Operativo Inteligente para el Despacho de Abogados Mexicano Moderno.**

**Resumen Ejecutivo:** Lexa CRM es una plataforma SaaS (Software as a Service) construida sobre Ruby on Rails 8, diseñada para ser el núcleo operativo de despachos de abogados en México. A diferencia de los CRMs tradicionales que son meros sistemas de registro, Lexa CRM integra de forma nativa el framework de agentes de IA `rdawn`. Esto transforma la plataforma en un "paralegal virtual" proactivo que automatiza tareas de alto valor, mitiga riesgos críticos (como el incumplimiento de plazos), mejora la comunicación con el cliente y captura ingresos que de otro modo se perderían. La arquitectura se basa en los principios de **Confianza, Contexto y Control**, garantizando que la IA opere de forma segura dentro del ecosistema de Rails, con pleno acceso a la lógica de negocio y bajo reglas estrictas.

### 2. Visión y Oportunidad del Mercado

**Visión:** Convertirnos en la plataforma de gestión legal líder en México, redefiniendo la productividad del abogado al automatizar el trabajo administrativo y permitir que los profesionales del derecho se centren en la estrategia legal y la representación de sus clientes.

**Problema:**
1.  **Alto Riesgo Operativo:** La gestión manual de plazos judiciales y procesales es propensa a errores humanos que pueden derivar en negligencia profesional.
2.  **Ineficiencia y Pérdida de Ingresos:** Los abogados dedican un tiempo desproporcionado a tareas no facturables (administración, seguimiento, comunicación repetitiva) y no registran con precisión todo el tiempo facturable.
3.  **Expectativas del Cliente Moderno:** Los clientes exigen transparencia y comunicación constante sobre el estado de sus casos, generando una carga de comunicación significativa para el despacho.
4.  **Seguridad de Datos:** La información legal es extremadamente sensible y requiere un manejo seguro y confidencial.

**Oportunidad:** El mercado legal mexicano está en una fase de modernización. Existe una brecha para una solución que no solo organice la información, sino que la utilice de manera inteligente. Al integrar `rdawn` de forma nativa, Lexa CRM ofrece una ventaja competitiva única: no es un CRM con una "integración de IA" externa y frágil, sino una plataforma concebida desde su núcleo para la automatización inteligente y segura.

### 3. Personas de Usuario (User Personas)

1.  **Lic. Ricardo Morales (Socio Director, 55 años):**
    *   **Metas:** Rentabilidad del despacho, reputación, mitigar riesgos, eficiencia del equipo.
    *   **Frustraciones:** Perder tiempo en supervisión administrativa, preocupado por posibles negligencias, la dificultad de medir la productividad real.
    *   **Necesita:** Un dashboard con métricas clave, alertas proactivas de riesgos y un sistema que asegure que el trabajo se hace de manera consistente y eficiente.

2.  **Lic. Sofía Herrera (Abogada Asociada, 32 años):**
    *   **Metas:** Gestionar su carga de expedientes, cumplir todos sus plazos, mantener a sus clientes informados, cumplir sus metas de horas facturables.
    *   **Frustraciones:** Olvidar registrar una llamada o un email, la tediosa tarea de crear documentos repetitivos, el estrés de tener múltiples plazos simultáneos.
    *   **Necesita:** Un asistente que le recuerde plazos, le ayude a capturar tiempo y le facilite la comunicación y la creación de documentos.

3.  **Ana García (Paralegal / Asistente Administrativa, 28 años):**
    *   **Metas:** Mantener los expedientes organizados, agendar citas y audiencias, dar seguimiento a la documentación, filtrar las comunicaciones iniciales.
    *   **Frustraciones:** Errores de tipeo al crear nuevos clientes, el vaivén de emails para confirmar una cita, la búsqueda de documentos en diferentes carpetas.
    *   **Necesita:** Herramientas de automatización para el "intake" de nuevos casos, plantillas de documentos y un sistema centralizado de información.

4.  **Pedro Martínez (Cliente, 45 años):**
    *   **Metas:** Entender qué está pasando con su caso, sentirse seguro de que sus abogados están trabajando en ello, poder acceder a documentos importantes.
    *   **Frustraciones:** La incertidumbre, no entender la jerga legal, tener que llamar constantemente para pedir una actualización.
    *   **Necesita:** Un portal seguro donde pueda ver el estado de su caso en un lenguaje claro y comunicarse de manera eficiente con su abogado.

### 4. Requerimientos Funcionales Detallados

#### Módulo 1: Core CRM (Fundamentos)
*   **Gestión de Expedientes (Casos):**
    *   Creación y gestión de `Expedientes`. Campos clave: Número de Expediente, Cliente, Contraparte, Tipo de Juicio (Civil, Mercantil, Amparo, etc.), Juzgado/Autoridad, Estado (Activo, En Archivo, Cerrado).
    *   Relación uno-a-muchos entre `Cliente` y `Expediente`.
*   **Gestión de Contactos:**
    *   Base de datos de `Contactos` (Clientes, Contrapartes, Testigos, Jueces).
    *   Campos: Nombre, RFC, CURP, Domicilio, Teléfonos, Emails.
*   **Agenda y Calendario:**
    *   Calendario para agendar Audiencias, Citas, Vencimientos.
    *   Integración bidireccional con Google Calendar / Outlook.
*   **Gestor Documental:**
    *   Subida y almacenamiento seguro de documentos asociados a cada `Expediente`.
    *   Versionado de documentos.
    *   Búsqueda de texto completo dentro de los documentos (integración con pg_search o similar).

#### Módulo 2: Finanzas y Facturación
*   **Entradas de Tiempo (Time Tracking):**
    *   Registro manual de tiempo facturable y no facturable.
    *   Asociación de cada entrada de tiempo a un `Expediente` y a una `Tarea`.
*   **Facturación (Integración CFDI 4.0):**
    *   Generación de pre-facturas a partir de las entradas de tiempo.
    *   Integración con un Proveedor Autorizado de Certificación (PAC) para timbrar facturas electrónicas (CFDI 4.0) con todos los requisitos fiscales de México.

#### Módulo 3: Portal del Cliente
*   **Acceso Seguro:** Login para clientes con `Devise`.
*   **Dashboard del Caso:** Vista simplificada del estado del `Expediente`, próximos eventos y últimas actividades (comunicado por el Agente de IA).
*   **Mensajería Segura:** Canal de comunicación directo con el despacho.
*   **Compartir Documentos:** Acceso a documentos que el despacho haya compartido explícitamente.

#### Módulo 4: "AI Copilot" (Funcionalidades Clave de `rdawn`)
1.  **Agente de Admisión (Intake) de Casos:** Procesa emails entrantes para crear borradores de `Clientes` y `Expedientes` automáticamente.
2.  **Agente Vigilante de Plazos:** Monitorea diariamente los plazos críticos, verifica el progreso de tareas asociadas y genera alertas inteligentes si detecta un riesgo.
3.  **Agente de Captura de Tiempo:** Sugiere borradores de entradas de tiempo basándose en la actividad registrada del abogado (emails enviados, documentos creados, llamadas registradas).
4.  **Agente de Comunicación con Cliente:** Responde preguntas básicas de los clientes en el portal 24/7, traduciendo el estado técnico del caso a un lenguaje claro y tranquilizador.
5.  **Agente Generador de Documentos:** Crea borradores de documentos legales comunes (demandas, contestaciones, promociones simples) a partir de plantillas y datos del `Expediente`.
6.  **Agente de Investigación (RAG):** Permite hacer preguntas en lenguaje natural sobre la base de conocimientos interna del despacho (documentos de casos anteriores, plantillas, guías).

### 5. Diseño de Integración Detallada con `rdawn`

Esta sección detalla cómo las herramientas de `rdawn` habilitarán las funcionalidades del "AI Copilot".

| Funcionalidad del AI Copilot | Workflow de `rdawn` y Herramientas Utilizadas |
| :--- | :--- |
| **1. Agente de Admisión de Casos** | **Disparador:** `ActionMailbox` recibe un email.<br>**Workflow:**<br>1. **`LLMTask`:** Parsea el email para extraer Nombre, Email, Teléfono, Resumen del caso.<br>2. **`ActiveRecordScopeTool`:** Ejecuta `User.find_by(email: ...)` para detectar duplicados.<br>3. **`DirectHandlerTask`:** Crea los registros `Cliente` y `Expediente` en estado `:needs_review`.<br>4. **`ActionMailerTool`:** Notifica al paralegal para revisión y validación. |
| **2. Agente Vigilante de Plazos** | **Disparador:** `CronTool` (ejecución diaria a las 6 AM).<br>**Workflow:**<br>1. **`ActiveRecordScopeTool`:** Busca `Expedientes` con plazos en los próximos 7 días: `scopes: [{ name: 'con_plazos_proximos' }]`.<br>2. **`PunditPolicyTool` (Loop):** Verifica que el agente tiene permiso para leer cada expediente (`action: 'show?'`).<br>3. **`LLMTask` (Condicional):** Si una tarea predecesora está incompleta, redacta una alerta inteligente y específica.<br>4. **`ActionCableTool` y `ActionMailerTool`:** Envía la alerta en tiempo real al dashboard del abogado (`turbo_stream`) y por email. |
| **3. Agente de Captura de Tiempo** | **Disparador:** `CronTool` (ejecución al final del día por usuario).<br>**Workflow:**<br>1. **`ActiveRecordScopeTool`:** Recopila la actividad del día para un usuario (`Comentarios`, `Documentos`, `Emails` creados hoy).<br>2. **`LLMTask`:** Resume las actividades en un formato de entrada de tiempo: "Llamada sobre caso X, redacción de email Y".<br>3. **`DirectHandlerTask`:** Crea `TimeEntry` con estado `:suggested`.<br>4. **`ActionCableTool`:** Actualiza la UI del abogado mostrando una insignia: "Tienes 5 entradas de tiempo sugeridas para revisar". |
| **4. Agente de Comunicación (Portal)** | **Disparador:** Mensaje de un cliente en el chat del portal.<br>**Workflow:**<br>1. **`PunditPolicyTool`:** Confirma que `current_client` puede ver el expediente (`record: client.case, action: 'show_portal?'`).<br>2. **`ActiveRecordScopeTool`:** Obtiene el estado y la última actividad del `Expediente`.<br>3. **`LLMTask`:** Recibe el estado técnico ("*Esperando acuerdo probatorio*") y lo traduce a lenguaje sencillo.<br>4. **`ActionCableTool`:** Envía la respuesta generada al cliente a través del chat en tiempo real (`broadcast_to_channel`). |
| **5. Agente Generador de Documentos** | **Disparador:** El abogado hace clic en "Generar Demanda Inicial".<br>**Workflow:**<br>1. **`DirectHandlerTask`:** Carga los datos del `Expediente` y del `Cliente`.<br>2. **`LLMTask`:** Recibe una plantilla de demanda y los datos del expediente. Rellena la plantilla y redacta las secciones de "Hechos" basándose en el resumen del caso.<br>3. **`DirectHandlerTask`:** Usa una gema (como `prawn` o `docx-templater`) para generar el archivo .pdf o .docx y lo guarda en el Gestor Documental. |
| **6. Agente de Investigación (RAG)** | **Disparador:** Abogado usa la barra de búsqueda de RAG.<br>**Workflow:**<br>1. **`ToolTask (vector_store_create)` (Setup):** Se indexan todos los documentos del despacho en un Vector Store de OpenAI.<br>2. **`ToolTask (file_search)`:** El agente realiza una búsqueda semántica de la pregunta del abogado en el Vector Store.<br>3. **`LLMTask`:** Analiza los resultados de la búsqueda y sintetiza una respuesta coherente, citando los documentos fuente. |

### 6. Requerimientos No Funcionales

*   **Seguridad:**
    *   Autenticación robusta con `Devise` (2FA opcional).
    *   Autorización granular con `PunditPolicyTool` para asegurar que agentes y usuarios solo accedan a lo que les corresponde.
    *   Encriptación de datos en tránsito (SSL/TLS) y en reposo.
    *   Cumplimiento con la **Ley Federal de Protección de Datos Personales en Posesión de los Particulares (LFPDPPP)**.
*   **Rendimiento:**
    *   Tiempo de carga de página < 2 segundos.
    *   Respuestas de API < 300ms.
    *   Uso de `ActiveJob` (con Sidekiq/GoodJob) para todas las tareas de `rdawn` y envío de emails para no bloquear la UI.
*   **Escalabilidad:** La arquitectura debe soportar desde abogados independientes hasta despachos de 50+ usuarios sin degradación del rendimiento.
*   **Confiabilidad:** Uptime del 99.8%. Backups diarios de la base de datos.

### 7. Consideraciones para el Mercado Mexicano

1.  **Terminología Legal:** La UI y la base de datos deben usar terminología mexicana: `Expediente`, `Amparo`, `Actor`, `Demandado`, `Juzgado de Distrito`, `Notificación por Estrados`, etc.
2.  **Facturación CFDI 4.0:** La integración con un PAC para emitir facturas electrónicas válidas ante el SAT es **no negociable**. Debe incluir todos los campos obligatorios.
3.  **Regulación de Datos:** El manejo de datos personales debe ser explícitamente compatible con la LFPDPPP, incluyendo avisos de privacidad y derechos ARCO.
4.  **Calendario Judicial:** El sistema debe ser flexible para manejar los calendarios y periodos vacacionales del Poder Judicial de la Federación y de los poderes judiciales locales.

### 8. Modelo de Negocio y Monetización

*   **Modelo:** SaaS por suscripción mensual o anual.
*   **Niveles (Tiers):**
    *   **Plan "Profesional" (por usuario):** Incluye todo el Core CRM, Gestor Documental y Portal del Cliente.
    *   **Plan "Despacho Inteligente" (por usuario, precio mayor):** Incluye todo lo del plan Profesional más el acceso completo al **AI Copilot** (todos los agentes de `rdawn`).
*   **Add-ons:** Almacenamiento extra, integraciones premium (e.g., plataformas de e-signature).

### 9. Roadmap Preliminar

*   **MVP (Lanzamiento en 3-4 meses):**
    *   Módulos Core CRM completos (Expedientes, Contactos, Agenda, Documentos).
    *   Módulo de Entradas de Tiempo.
    *   **AI Copilot (MVP):** Agente de Admisión (Intake) y Agente Vigilante de Plazos. Estos dos resuelven los dolores más grandes (eficiencia y riesgo).
*   **Versión 1.1 (Post-lanzamiento +3 meses):**
    *   Portal del Cliente completo.
    *   AI Copilot: Añadir Agente de Captura de Tiempo y Agente de Comunicación con Cliente.
    *   Integración de facturación CFDI 4.0.
*   **Futuro (6-12 meses):**
    *   AI Copilot: Añadir Agente Generador de Documentos y Agente de Investigación (RAG).
    *   Integraciones con plataformas de e-signature.
    *   App móvil (posiblemente con Turbo Native).

### 10. Métricas de Éxito (KPIs)

*   **Adquisición:** Tasa de conversión de prueba a pago.
*   **Retención:** Tasa de Churn mensual < 3%.
*   **Engagement:**
    *   Número de expedientes gestionados por despacho.
    *   **Tasa de adopción del AI Copilot:** % de usuarios del plan "Despacho Inteligente" que interactúan con los agentes de `rdawn` semanalmente.
    *   Número de alertas de plazos generadas y atendidas.
*   **Valor Percibido:** Net Promoter Score (NPS).

### 11. Epics y User Stories Detalladas (Ejemplos)

Aquí se desglosan los requerimientos funcionales en unidades de trabajo manejables, centradas en el valor para el usuario.

#### **Epic 1: Vigilante de Plazos Proactivo**
*Descripción: Como despacho, necesitamos un sistema automatizado que prevenga el incumplimiento de plazos críticos, reduciendo el principal riesgo de negligencia profesional y brindando tranquilidad.*

*   **User Story 1.1 (Configuración):**
    > **Como** Socio Director (Ricardo), **quiero** configurar los tipos de notificaciones de plazos (ej. 15, 7 y 3 días antes) y los canales (email, dashboard, SMS para la última alerta), **para** adaptar el sistema a las políticas de riesgo del despacho.

*   **User Story 1.2 (Visualización):**
    > **Como** Abogada Asociada (Sofía), **quiero** ver un widget en mi dashboard principal que muestre mis próximos 5 plazos, coloreados por urgencia (amarillo, naranja, rojo), **para** poder priorizar mi trabajo de un solo vistazo al iniciar sesión.

*   **User Story 1.3 (Alerta Inteligente - `rdawn`):**
    > **Como** sistema (`rdawn` Agent), **quiero** ejecutar un job diario que identifique plazos críticos y, si una tarea clave no está completa, generar y enviar una alerta específica que no solo diga "el plazo vence", sino "el plazo para 'Presentar Contestación' vence en 3 días y la tarea 'Recopilar pruebas del cliente' aún está pendiente", **para** proporcionar contexto accionable, no solo un recordatorio genérico.

*   **User Story 1.4 (Interacción):**
    > **Como** Abogada Asociada (Sofía), **quiero** poder hacer clic en una notificación de plazo y que me lleve directamente al expediente y a la lista de tareas pendientes relacionadas, **para** poder actuar sobre la alerta de inmediato sin tener que buscar la información.

#### **Epic 2: Admisión Inteligente de Casos**
*Descripción: Como despacho, queremos automatizar el proceso de alta de nuevos clientes y casos a partir de comunicaciones iniciales, para acelerar nuestra respuesta, eliminar errores de entrada de datos y permitir que el personal se enfoque en la evaluación del cliente.*

*   **User Story 2.1 (Creación Automática - `rdawn`):**
    > **Como** sistema (`rdawn` Agent), **quiero** monitorear una bandeja de entrada de correo (`nuevos@lexacrm.com`) y, al recibir un email, usar un LLM para extraer las entidades (nombre, email, teléfono, resumen) y crear un `Cliente` y un `Expediente` en estado "Borrador - Requiere Revisión", **para** eliminar la entrada manual de datos.

*   **User Story 2.2 (Revisión y Aprobación):**
    > **Como** Paralegal (Ana), **quiero** recibir una notificación en mi dashboard sobre un "Nuevo Caso Potencial para Revisión" y ver todos los campos pre-poblados por la IA junto con el email original, **para** poder validar la información, completar lo que falte y aprobar la creación del caso con un solo clic.

*   **User Story 2.3 (Manejo de Excepciones):**
    > **Como** sistema (`rdawn` Agent), **quiero** que si no puedo parsear un email con suficiente confianza, en lugar de crear un borrador, cree una tarea simple para la Paralegal (Ana) que diga "Revisar email de posible cliente" y adjunte el correo, **para** asegurar que ningún prospecto se pierda, incluso si no puede ser automatizado.

### 12. Arquitectura Técnica y Stack Tecnológico

*   **Backend:**
    *   **Lenguaje/Framework:** Ruby 3.3+, Ruby on Rails 8.0+
    *   **Agentes de IA:** `rdawn` como gema central.
    *   **Autenticación:** `devise`
    *   **Autorización:** `pundit` (y `PunditPolicyTool` de `rdawn`)
    *   **Jobs en Segundo Plano:** `GoodJob` o `Sidekiq` (para ejecutar todos los workflows de `rdawn` de forma asíncrona).
    *   **API:** `jbuilder` o `fast_jsonapi` si se exponen endpoints para una futura app móvil.
*   **Frontend:**
    *   **Framework:** Hotwire (Turbo y Stimulus). Permite una experiencia de aplicación de página única (SPA-like) con la simplicidad del desarrollo en Rails.
    *   **CSS:** Tailwind CSS. Para un desarrollo de UI rápido, consistente y moderno.
    *   **Componentes:** ViewComponent para crear componentes de vista reutilizables y testeables.
*   **Base de Datos:**
    *   **PostgreSQL 15+:** Por su robustez, soporte para tipos de datos avanzados (JSONB) y excelente rendimiento con Rails.
*   **Infraestructura:**
    *   **Hosting:** AWS (usando Elastic Beanstalk o EKS para escalar) o Heroku (para un despliegue y gestión más sencillos en las primeras etapas).
    *   **Almacenamiento de Archivos:** Amazon S3 o Google Cloud Storage (para guardar los documentos de los expedientes de forma segura y escalable).
    *   **Caché/Jobs:** Redis (si se usa Sidekiq).
*   **Servicios Externos y APIs:**
    *   **IA:** OpenAI API (gestionada a través de `rdawn`).
    *   **Facturación:** API de un PAC mexicano (ej. Facturama, SW Sapiens, Finkok) para el timbrado de CFDI 4.0.
    *   **Calendario:** Google Calendar API, Microsoft Graph API.
    *   **Notificaciones SMS:** Twilio API.

### 13. Principios de Diseño UX/UI

1.  **Claridad sobre Abundancia:** El dashboard de un abogado debe ser un centro de control, no un mar de datos. La UI priorizará las acciones y alertas más importantes (plazos críticos, tareas pendientes, notificaciones no leídas) en la parte superior.
2.  **Confianza a través de la Transparencia:** Cada vez que la IA realice una acción (sugerir una entrada de tiempo, crear un borrador de caso), la UI lo indicará claramente con una etiqueta "Sugerencia de IA" o similar. El usuario siempre debe saber qué fue automatizado y qué fue entrada manual.
3.  **Automatización Asistida, no Forzada:** El paradigma es "humano en el bucle" (Human-in-the-loop). La IA sugiere, el humano aprueba. Esto es crítico para ganar la confianza de una profesión tan meticulosa como la abogacía. Ejemplo: un botón "Aprobar Borrador" en lugar de creación directa.
4.  **Flujos de Trabajo Ininterrumpidos:** El diseño minimizará los cambios de contexto. Si una alerta de plazo aparece, un clic debe abrir un modal o un panel lateral con la información del expediente, sin forzar al usuario a abandonar la página actual. Se usarán `Turbo Frames` y `Turbo Streams` extensivamente.
5.  **Diseño Profesional y Sobrio:** La estética será limpia, moderna y profesional. La paleta de colores inspirará confianza y seriedad (tonos de azul, gris, blanco), con colores de acento (rojo, amarillo) reservados para alertas y notificaciones críticas.

### 14. Estrategia de Go-to-Market (GTM)

*   **Fase 1 - Lanzamiento Beta (Mercado Inicial):**
    *   **Objetivo:** Adquirir los primeros 10-20 despachos "amigos".
    *   **Perfil:** Despachos pequeños (1-15 abogados) en ciudades principales (CDMX, Monterrey, Guadalajara) que ya muestren interés en la tecnología.
    *   **Táctica:** Contacto directo, demos personalizadas. Ofrecer un precio de "fundador" con descuento a cambio de retroalimentación detallada.
*   **Fase 2 - Crecimiento Sostenido:**
    *   **Marketing de Contenidos:** Crear un blog y whitepapers con temas como "Cómo evitar la negligencia profesional con tecnología", "Guía del CFDI 4.0 para abogados", "5 tareas que tu despacho debería automatizar". Optimizado para SEO en México.
    *   **Publicidad Digital:** Campañas en LinkedIn Ads segmentadas por "Abogado", "Socio", "Gerente Legal" en México. Google Ads para búsquedas como "software para abogados mexico", "crm legal".
    *   **Alianzas Estratégicas:** Colaborar con Colegios y Barras de Abogados para ofrecer webinars y talleres. Contactar a consultores de tecnología legal.
    *   **Modelo Freemium/Prueba Gratuita:** Ofrecer una prueba gratuita de 14 días del plan "Despacho Inteligente" para que los usuarios experimenten el poder del "AI Copilot".

### 15. Análisis de Riesgos y Planes de Mitigación

*   **Riesgo: "Alucinaciones" del LLM y Precisión de la IA.**
    *   **Descripción:** La IA podría interpretar incorrectamente un email o generar un resumen de hechos impreciso.
    *   **Mitigación:** **Principio de "Humano en el Bucle"**. Ninguna acción crítica (creación de un cliente, envío de un documento) se completa sin la validación humana. La IA crea *borradores* y *sugerencias*, no registros finales. El `DirectHandlerTask` en los workflows de `rdawn` se usará para validar los datos generados por el LLM contra la lógica de negocio de la aplicación antes de guardarlos.

*   **Riesgo: Lenta Adopción por parte de los Abogados.**
    *   **Descripción:** La profesión legal puede ser conservadora y reacia a adoptar nuevas tecnologías.
    *   **Mitigación:** **Onboarding Excepcional.** Crear tutoriales en video, guías paso a paso y un servicio de soporte al cliente proactivo. El marketing debe enfocarse en los beneficios tangibles: **1) Reducción de Riesgo, 2) Aumento de Horas Facturables, 3) Ahorro de Tiempo.** El beneficio debe ser abrumadoramente claro.

*   **Riesgo: Regulatorio y de Cumplimiento.**
    *   **Descripción:** Cambios en la ley de protección de datos (LFPDPPP) o en las reglas del SAT para el CFDI.
    *   **Mitigación:** **Arquitectura Modular.** La lógica de timbrado de CFDI será un servicio aislado (un "adapter") que pueda ser actualizado o reemplazado fácilmente. Contratar asesoría legal para revisar periódicamente las políticas de manejo de datos y los términos de servicio.

*   **Riesgo: Costos de la API de OpenAI.**
    *   **Descripción:** Un uso intensivo por parte de los clientes podría disparar los costos de la API.
    *   **Mitigación:**
        1.  **Optimización de Prompts:** Diseñar prompts eficientes.
        2.  **Selección de Modelos:** Usar modelos más económicos como `gpt-4o-mini` para tareas de clasificación y extracción, y modelos más potentes solo cuando sea necesario para la redacción.
        3.  **Caché Inteligente:** Almacenar en caché las respuestas a preguntas repetitivas (especialmente para el Agente de Investigación RAG).
        4.  **Límites de Uso:** El plan "Despacho Inteligente" podría incluir un número "justo" de acciones de IA por mes, con la opción de comprar paquetes adicionales.

*   **Riesgo: Seguridad y Confidencialidad de los Datos.**
    *   **Descripción:** Una brecha de seguridad en un CRM legal sería catastrófica.
    *   **Mitigación:** **Seguridad desde el Diseño.**
        1.  Uso estricto de `PunditPolicyTool` en **todos** los workflows de `rdawn` que accedan a datos.
        2.  Auditorías de seguridad regulares por terceros.
        3.  Políticas de contraseñas fuertes y 2FA obligatorio para acceder a datos sensibles.
        4.  Capacitación constante al equipo de desarrollo en prácticas de codificación segura.
