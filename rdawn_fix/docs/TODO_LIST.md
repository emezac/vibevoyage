### **Detailed TODO List: Building the `rdawn` Framework as a Ruby Gem**

**Sprint Objective:** Create version 0.1.0 of the `rdawn` gem, establishing the foundations of the Workflow Management System (WMS), integration with LLMs via `raix`/`open_router`, and the structure for optional Rails integration.

**Priority Legend:**
*   🔴 **Critical:** Fundamental for the sprint's basic functionality.
*   🟡 **Important:** Necessary for a complete feature, but may have temporary workarounds.
*   🟢 **Desirable:** Improves quality or developer experience; can be deferred if time is short.

---

#### **🚀 Phase 1: Project Scaffolding and Core Data Models (Week 1)**

*   **1.1: Gem Setup (Day 1)**
    *   `[x]` 🔴 **Create the gem structure:** Run `bundle gem rdawn` to generate the project skeleton.
    *   `[x]` 🔴 **Define the `rdawn.gemspec`:**
        *   Complete metadata: `name`, `version` ("0.1.0"), `authors`, `summary`, `description`, `license` ("MIT").
        *   Add runtime dependencies: `spec.add_dependency "raix"`, `spec.add_dependency "open_router"`, `spec.add_dependency "activesupport"` (for utilities like `HashWithIndifferentAccess`), `spec.add_dependency "httpx"` (for tools), `spec.add_dependency "zeitwerk"`.
        *   Add development dependencies: `spec.add_development_dependency "rspec"`, `spec.add_development_dependency "rubocop"`, `spec.add_development_dependency "pry"`.
    *   `[x]` 🟡 **Configure RSpec:**
        *   Create `spec/spec_helper.rb` for test configuration.
        *   Create the `.rspec` file in the root with default options (`--format documentation`).
    *   `[x]` 🟡 **Configure RuboCop:**
        *   Create `.rubocop.yml` in the root with basic style rules (e.g., inherit from `rubocop-rspec`).

*   **1.2: Core Data Model Implementation (Days 2-3)**
    *   `[x]` 🔴 **`lib/rdawn/task.rb`:**
        *   Create the `Rdawn::Task` class.
        *   Define attributes with `attr_accessor`: `task_id`, `name`, `status` (`:pending`, `:running`, etc.), `input_data` (Hash), `output_data` (Hash), `is_llm_task` (Boolean), `tool_name` (String), `max_retries`, `retry_count`.
        *   Define flow control attributes: `next_task_id_on_success`, `next_task_id_on_failure`, `condition`.
        *   Implement state methods: `mark_running`, `mark_completed(output)`, `mark_failed(error)`.
        *   Add the `to_h` method for serialization.
    *   `[x]` 🔴 **`spec/rdawn/task_spec.rb`:** Write unit tests for the `Task` class (initialization, state changes).
    *   `[x]` 🔴 **`lib/rdawn/workflow.rb`:**
        *   Create the `Rdawn::Workflow` class.
        *   Define attributes: `workflow_id`, `name`, `status`, `tasks` (a Hash to store `Rdawn::Task` by `task_id`), `variables` (Hash).
        *   Implement `add_task(task)` and `get_task(task_id)`.
    *   `[x]` 🔴 **`spec/rdawn/workflow_spec.rb`:** Write tests for `add_task` and `get_task`.
    *   `[x]` 🔴 **`lib/rdawn/agent.rb`:**
        *   Create the `Rdawn::Agent` class.
        *   Define `initialize(workflow:, llm_interface:)`.
        *   Define a `run(initial_input: {})` method that instantiates and executes the `WorkflowEngine`.

*   **1.3: Custom Error Definitions (Day 4)**
    *   `[x]` 🟡 **`lib/rdawn/errors.rb`:**
        *   Create a `Rdawn::Errors` module.
        *   Define custom error classes: `ConfigurationError`, `TaskExecutionError`, `ToolNotFoundError`, `VariableResolutionError`.

*   **1.4: Initial Documentation (Day 5)**
    *   `[x]` 🟢 **Update `README.md`:** Add a project description, v0.1.0 goals, and a sketch of how it will be used.
    *   `[x]` 🟢 **Configure YARD:** Add `yard` to the `Gemfile` and set up a Rake task to generate documentation (`rake yard`).

---

#### **⚙️ Phase 2: Execution Engine and Core Capabilities (Week 2)**

*   **2.1: WorkflowEngine - Sequential Execution (Days 6-7)**
    *   `[x]` 🔴 **`lib/rdawn/workflow_engine.rb`:**
        *   Create the `Rdawn::WorkflowEngine` class.
        *   Implement the main loop in the `run` method.
        *   Add logic to find the initial task and follow the `next_task_id_on_success` chain.
        *   Implement an `execute_task(task)` method that for now just simulates execution (marks as completed).
    *   `[x]` 🔴 **`spec/rdawn/workflow_engine_spec.rb`:** Write a test for a simple sequential workflow (2-3 tasks) and verify they execute in order.

*   **2.2: `LLMInterface` and Tools (Days 8-9)**
    *   `[x]` 🔴 **`lib/rdawn/llm_interface.rb`:**
        *   Create the `Rdawn::LLMInterface` class.
        *   Implement `initialize` to receive configuration (e.g., provider, API key).
        *   Implement `execute_llm_call(prompt:, model_params: {})` which internally uses `Raix.chat` with the `OpenRouter` provider.
    *   `[x]` 🔴 **`lib/rdawn/tool_registry.rb`:**
        *   Create the `Rdawn::ToolRegistry` class (likely as a singleton or a single instance).
        *   Implement `register(name, tool_object)` and `execute(name, input_data)`.
    *   `[x]` 🔴 **Update `WorkflowEngine#execute_task`:**
        *   Add logic: if `task.is_llm_task`, call `LLMInterface`.
        *   If `task.tool_name` is present, call `ToolRegistry`.
    *   `[x]` 🟡 **`spec/rdawn/llm_interface_spec.rb`:** Test the interface by mocking the call to `Raix.chat`.
    *   `[x]` 🟡 **`spec/rdawn/tool_registry_spec.rb`:** Test registering and executing a mock tool.

*   **2.3: `DirectHandlerTask` (Day 10)**
    *   `[x]` 🔴 **`lib/rdawn/tasks/direct_handler_task.rb`:**
        *   Create the subclass `Rdawn::DirectHandlerTask < Rdawn::Task`.
        *   Add the `handler` attribute (`Proc` or `lambda`).
    *   `[x]` 🔴 **Update `WorkflowEngine#execute_task`:** Add an `elsif task.is_a?(DirectHandlerTask)` to execute the `handler` directly.
    *   `[x]` 🟡 **`spec/rdawn/tasks/direct_handler_task_spec.rb`:** Test that a task of this type correctly executes its `Proc`.

---

#### **🧩 Phase 3: Advanced Flow Logic and (Optional) Rails Integration (Week 3)**

*   **3.1: Variable Resolution and Conditionals (Days 11-12)**
    *   `[x]` 🔴 **`lib/rdawn/variable_resolver.rb`:**
        *   Implement a `VariableResolver` module or class.
        *   Create a `resolve(input_data, context)` method that substitutes `${...}`. Support nested hash access (e.g., `${task1.output.user.name}`).
    *   `[x]` 🔴 **Update `WorkflowEngine`:**
        *   Before executing a task, call `VariableResolver.resolve`.
        *   After a task completes, add its `output_data` to the general workflow context.
        *   Implement the logic for `next_task_id_on_success/failure` and evaluate the `:condition` field if it exists.
    *   `[x]` 🟡 **`spec/rdawn/variable_resolver_spec.rb`:** Test cases for variable resolution.
    *   `[x]` 🟡 **`spec/rdawn/workflow_engine_spec.rb`:** Add tests for workflows with data dependencies and conditionals.

*   **3.2: Optional Rails Integration (Days 13-14)**
    *   `[x]` 🟡 **Create `lib/rdawn/rails.rb`:** This file will contain all Rails-specific logic and will only be loaded by the user in a Rails environment.
    *   `[x]` 🟢 **Create a Railtie:** In `rails.rb`, define an `Rdawn::Railtie` to hook into the Rails initialization process.
    *   `[x]` 🟡 **Installation Generator:** `lib/generators/rdawn/install_generator.rb`.
        *   It should create `config/initializers/rdawn.rb`.
        *   The initializer will configure the gem (e.g., `Rdawn.configure { |config| ... }`).
    *   `[x]` 🟡 **Active Job Integration:**
        *   Define a base class `Rdawn::ApplicationJob < ActiveJob::Base` in `rdawn/rails.rb`.
        *   Create a generic job, e.g., `Rdawn::WorkflowJob`, that accepts a workflow class name and inputs, then instantiates and runs it in `perform`.
    *   `[x]` 🟢 **Document Integration:** Create a guide in `docs/RAILS_INTEGRATION.md` explaining how to use `rdawn` in a Rails application, including how to pass `current_user` and use Active Record models in `DirectHandlerTask`s.

*   **3.3: Advanced Features (RAG, MCP) (Day 15 - Completed)**
    *   `[x]` 🟢 **Implemented Vector Store tools:**
        *   ✅ VectorStoreTool: Complete CRUD operations for OpenAI vector stores
        *   ✅ FileUploadTool: Upload and manage files for vector stores
        *   ✅ FileSearchTool: Semantic search through vector stores (RAG)
        *   ✅ WebSearchTool: Real-time web search integration
        *   ✅ Enhanced LLMInterface with `use_file_search` and `vector_store_ids` parameters
        *   ✅ Tool registry integration with 16 registered tools
        *   ✅ Comprehensive documentation and examples
    *   `[x]` 🟢 **Plan MCP Integration:**
        *   ✅ Investigate how `ruby_llm` handles MCP connections (stdio).
        *   ✅ Design a dynamic `MCPTool` that can be registered in the `ToolRegistry`.
        *   ✅ Identify necessary changes in `WorkflowEngine` to handle `async` calls to MCP tools.
        *   ✅ **MCPTool Class**: Direct MCP server communication with JSON-RPC 2.0 over stdio
        *   ✅ **MCPTaskExecutor Class**: Async execution with thread pool management
        *   ✅ **MCPManager Class**: High-level interface for server management
        *   ✅ **MCPTask Class**: Workflow-integrated MCP tasks
        *   ✅ **ToolRegistry Integration**: Auto-registration of MCP tools
        *   ✅ **WorkflowEngine Support**: Async and sync MCP task execution
        *   ✅ **Error Handling**: Comprehensive error recovery and logging
        *   ✅ **Rails Integration**: Seamless Rails app integration
        *   ✅ **Documentation**: Complete MCP integration guide and examples

---

#### **📦 Phase 4: Polishing and Packaging (Week 4)**

*   **4.1: Integration Tests (Days 16-17)**
    *   `[x]` 🟡 Write 1-2 complete integration tests that run a workflow from start to finish, mocking external calls (LLM, tools).
    *   `[~]` 🟢 (If Rails integration was done) Create a minimal Rails app in `spec/dummy` to test Active Job integration.

*   **4.2: Final Documentation (Days 18-19)**
    *   `[x]` 🔴 **Complete the `README.md`:** Include a full usage example, the basic architecture, and the framework's philosophy.
    *   `[x]` 🟡 **Generate YARD documentation:** Run `rake yard` and ensure the output is clear.
    *   `[x]` 🟡 **Write guides in `docs/`:** Create guides for `WORKFLOWS.md`, `TOOLS.md`, and `DIRECT_HANDLERS.md`.

*   **4.3: Release Preparation (Day 20)**
    *   `[x]` 🔴 **Review and finalize the `.gemspec`**.
    *   `[x]` 🔴 **Build the gem:** `gem build rdawn.gemspec`.
    *   `[x]` 🟡 **Test the gem locally:** Install the built gem in a test project.
    *   `[~]` 🟢 **Publish the gem (v0.1.0):** `gem push rdawn-0.1.0.gem` (Ready for publishing when desired).

