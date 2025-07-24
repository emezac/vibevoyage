### **Product Requirements Document (PRD): `rdawn`**

**Version:** 1.0
**Date:** July 16, 2025
**Status:** Draft

#### **1. Executive Summary**

`rdawn` is an open-source framework for Ruby, built on Ruby on Rails 8.0, designed for creating robust, **web-native AI agents**. Unlike agentic frameworks that operate as external services, `rdawn` is envisioned as the **central nervous system of a SaaS application**, allowing developers to build AI capabilities that are deeply integrated with the application's data models, business logic, and user context. Its key differentiator is an explicit Workflow Management System (WMS) that orchestrates complex tasks, leveraging the full power of the Rails ecosystem—from Active Record to Active Job and Action Cable—to create a new category of **Agentic SaaS**.

#### **2. Vision and Motivation**

The current narrative that "AI agents will replace SaaS" is an oversimplification. The true transformation is not replacement, but **fusion**: SaaS will become agentic. Web applications will evolve from passive tools that respond to clicks into **active, proactive partners** that understand user goals and work autonomously to achieve them.

`rdawn` is created to be the catalyst for this transformation within the Ruby on Rails ecosystem, an ideal environment for building complex, data-centric business applications. The vision for `rdawn` is to enable Rails developers to build AI features that don't feel like an add-on, but as a fundamental, intelligent, and native part of the product.

#### **3. The Problem to Solve**

Currently, Rails developers wishing to integrate advanced AI face a dilemma:

1.  **Build from Scratch:** Creating the logic for orchestration, state management, and tool chaining is complex and error-prone.
2.  **Use External Services (Python):** Integrating Python-based agents requires building and maintaining internal APIs, managing network communication, duplicating business logic, and facing enormous security and data context challenges. The external agent is a "second-class citizen" that does not understand the richness of the Rails ecosystem.

`rdawn` solves this problem by providing a **Rails-native solution** that eliminates this friction, allowing agents to operate with unprecedented knowledge and action capability from within the application itself.

#### **4. Goals and Objectives (Version 1.0)**

*   **Primary Goal:** To establish `rdawn` as the go-to framework for building copilots and AI agents in Ruby on Rails SaaS applications.

*   **Key Objectives:**
    1.  **Implement the Core WMS in Ruby:** Create the `Rdawn::Agent`, `Rdawn::Workflow`, and `Rdawn::Task` classes (including `DirectHandlerTask`), which form the heart of the orchestration system.
    2.  **Deep Integration with Active Record:** The variable resolution engine and `DirectHandlerTask`s must be able to interact natively with Active Record models (`User.find`, `project.tasks.create!`).
    3.  **Integration with Active Job:** Allow long-running `rdawn` tasks to be executed in the background using the Active Job infrastructure (with backends like Sidekiq or GoodJob).
    4.  **Extensible Tool System:** Provide a `Rdawn::ToolRegistry` where developers can easily register their own tools, which can be simple Ruby modules or service classes.
    5.  **Integration with OpenAI File Search:** Implement RAG (Retrieval-Augmented Generation) capabilities by allowing LLM tasks to use OpenAI's `file_search` tool to query Vector Stores.
    6.  **Packaging as a Gem:** Ensure the framework is a Rails `gem`, easily installable and configurable through an initializer (`config/initializers/rdawn.rb`).

#### **5. Design Philosophy: The "Rails Native Partner"**

The fundamental competitive advantage of `rdawn` lies not in the LLM's capabilities themselves, but in its **symbiosis with the Ruby on Rails framework**. An `rdawn` agent is not an external service; it is a first-class citizen of the application. This philosophy is based on the following pillars:

1.  **Native Access to the Data Model (Active Record):** An `rdawn` agent does not need an API to read or write to the database. It can execute `Project.find(1).tasks.late` directly. This is faster, more secure, and leverages all existing business logic (associations, validations, scopes, callbacks).
2.  **Integrated User Context and Security (Devise & Pundit):** The agent operates on behalf of a `current_user`. Before executing an action, it can and must check permissions using the application's authorization system (e.g., `policy(task).update?`). The agent will never be able to do something the user would not be permitted to do.
3.  **Leveraging the Web Gem Ecosystem:**
    *   **Background Jobs (Active Job):** Long tasks like "Generate a 10-page report" become a simple `RiskAnalysisAgentJob.perform_later(project)`.
    *   **Notifications (Action Mailer / Noticed):** The agent can send emails or create notifications natively.
    *   **Real-Time Interactivity (Action Cable & Turbo):** An agent can finish its work and send the results directly to the user's browser via a `Turbo Stream`, updating the UI without a page reload. The user experience is spectacular.
4.  **Simplified "Majestic Monolith" Architecture:** It eliminates the need to build, version, and maintain internal APIs just so the agent can communicate with the application. The agent's logic lives in the same codebase, simplifying development, testing, and refactoring.

#### **6. Architecture and Core Components**

`rdawn` will adapt the "Dawn" architecture to the Ruby on Rails paradigm:

*   **`Rdawn::Agent`**: The entity that executes a `Workflow`. Configured with an ID, name, and an `Rdawn::LLMInterface`. Can be associated with a `current_user`.
*   **`Rdawn::Workflow`**: The object that defines the orchestration logic. Contains a collection of `Rdawn::Task`.
*   **`Rdawn::Task`**: The unit of work.
    *   **Key Attributes:** `task_id`, `name`, `status`, `input_data` (with support for `${...}` variables), `is_llm_task`, `tool_name`, `next_task_id_on_success`/`failure`, `condition`.
    *   **File Search Parameters:** `use_file_search`, `file_search_vector_store_ids`.
    *   **Subclasses:**
        *   **`Rdawn::DirectHandlerTask`**: Directly executes a Ruby code block (`Proc` or `lambda`), or a Rails service class. This is the cornerstone for integration with Active Record and business logic.
*   **`Rdawn::WorkflowEngine` (WMS):** The orchestrator.
    *   **Variable Resolution:** Resolves `${...}` references using the workflow context.
    *   **Task Execution:** Selects the appropriate execution strategy (LLM, Tool, DirectHandler).
    *   **Active Job Integration:** Capable of enqueuing a `Task`'s execution in a job for asynchronous processing.
*   **`Rdawn::ToolRegistry`**: Registry for reusable tools (Ruby modules or classes).
*   **Rails Integration:**
    *   **Generators:** `rails g rdawn:workflow my_workflow` to create workflow templates.
    *   **Initializer:** `config/initializers/rdawn.rb` to configure the gem (e.g., LLM API keys, default settings).
    *   **Concerns/Mixins:** Modules that can be included in models or controllers to facilitate interaction with `rdawn` agents.

#### **7. Key Features (v1.0)**

| Feature | Description |
| :--- | :--- |
| **Workflow Engine** | Executes sequential and conditional workflows. |
| **`DirectHandlerTask`** | Executes Ruby code and Rails logic directly. |
| **Active Record Integration** | Handlers can query and manipulate models. |
| **Active Job Integration** | `Rdawn::Agent.run_later(workflow, initial_input)` for background execution. |
| **LLM Interface (OpenAI)** | Connector for `client.chat.completions.create` using the `ruby-openai` gem. |
| **File Search (RAG)** | Support for `use_file_search` and `vector_store_ids` in LLM tasks. |
| **Tool System** | `Rdawn::ToolRegistry` to register and execute tools. |
| **Vector Store Tools** | Includes basic tools to manage OpenAI Vector Stores (`vector_store_create`, `upload_file_to_vector_store`, etc.). |
| **Variable Resolution** | Support for `${...}` syntax to pass data between tasks, including nested hash access. |
| **Configuration** | Loads configuration from a Rails initializer and environment variables. |
| **Documentation & Testing** | Comprehensive documentation and a `TestHarness` to facilitate workflow testing. |

#### **8. Ideal Use Cases and SaaS Applications**

`rdawn` is optimized for building AI features that are core to the value proposition of a SaaS product.

1.  **CRM / Project Management Copilot (e.g., Basecamp/Jira on Rails):**
    *   **Why it's ideal:** An `rdawn` agent can query `Project.find_by_name(...)`, create `project.tasks.create(...)`, and check permissions with Pundit. The user experience can be made real-time with Turbo Streams. This is the archetype of the "killer app" for `rdawn`.
2.  **CRM for Lawyers (e.g., Clio/MyCase on Rails):**
    *   **Why it's ideal:** The concepts of **Trust, Context, and Control** are paramount. An `rdawn` agent lives inside the application, inheriting security from Devise/Pundit (trust), accessing `Case` and `Document` models (context), and following strict legal workflows (control).
3.  **E-commerce Platform (e.g., Solidus/Spree):**
    *   **Why it's ideal:** An `rdawn` agent can act as a "personal shopper" by querying `Spree::Product.where(...)`, or as an inventory manager that creates alerts (`ActionMailer`) when `Spree::StockItem.count_on_hand` drops below a threshold, all natively.

#### **9. Technical Approach and Dependencies**

*   **Language:** Ruby 3.4.5
*   **Framework:** Ruby on Rails 8.0
*   **Key Dependencies (Gems):**
    *   `activesupport`, `activejob`: For utilities and background jobs.
    *   `ruby-openai`: For the LLM interface.
    *   `httpx` or `faraday`: For API calls in tools.
    *   `zeitwerk`: For gem file loading.
*   **Testing:** RSpec will be the primary testing framework.

#### **10. Developer Experience (DevEx)**

*   **Simple Installation:** `bundle add rdawn` and `rails g rdawn:install`.
*   **Code Generators:** `rails g rdawn:workflow <name>` and `rails g rdawn:tool <name>` to create templates.
*   **Centralized Configuration:** A single `config/initializers/rdawn.rb` file.
*   **Clear Documentation:** Detailed guides on how to integrate `rdawn` with Rails components like Active Job and Pundit.
*   **Test Harness (`TestHarness`):** A utility to make writing tests for workflows easier, allowing for simple mocking of LLM and tool responses.

#### **11. Risks and Mitigation**

*   **Risk:** The AI ecosystem in Ruby is less mature than in Python.
    *   **Mitigation:** Build upon the official `ruby-openai` gem and design an abstract `LLMInterface` to allow for adding other providers in the future. The value is not in ML libraries, but in the integration with Rails.
*   **Risk:** Concurrent performance can be a concern (Global VM Lock).
    *   **Mitigation:** The primary use case (interaction with external APIs) is I/O-bound, not CPU-bound. Native integration with Active Job for long-running tasks is the idiomatic and recommended solution.
*   **Risk:** Maintaining compatibility with future Rails versions.
    *   **Mitigation:** Adhere to public Rails APIs and maintain a robust test suite that runs against different Rails versions.

#### **12. Success Metrics**

*   **Adoption:** Number of Rails applications integrating `rdawn`.
*   **Ease of Use:** A Rails developer can build a basic copilot in less than a day.
*   **Performance:** Background tasks integrate seamlessly with Sidekiq/GoodJob.
*   **Community:** External contributions to the project, creation of third-party `rdawn` tools.

#### **13. Future Roadmap (Post v1.0)**

*   **Action Cable Integration:** Tools and guides for sending agent results to the UI in real-time.
*   **Support for Multiple LLMs:** Add connectors for other providers like Anthropic or Google.
*   **Dynamic Workflow Generation (JSON):** Ability for an agent to generate the definition of another workflow as a JSON object, to then be interpreted and executed.
*   **MCP (Model Context Protocol) Integration:** Implement an `MCPTool` to interact with standardized external tools.
*   **ML-Based Optimization:** (Very long-term) Analyze workflow executions to suggest optimizations.

---
