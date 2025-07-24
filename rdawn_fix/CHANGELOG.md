# Changelog

## [v1.1.0] - 2025-07-18 - OpenAI Integration Update

### ✅ Fixed
- **Rails Integration**: Fixed configuration parameter names (`default_model` → `llm_model`)
- **OpenAI API**: Direct HTTP integration replacing problematic Raix dependency
- **Tool Registration**: Fixed `register_advanced_tools` API key parameter
- **Provider Configuration**: Corrected `llm_provider` settings for OpenAI

### 🚀 Added
- **Direct OpenAI API**: Native HTTP integration with comprehensive error handling
- **ActionCableTool**: Real-time UI updates via Turbo Streams and Action Cable
  - ✅ **Production-tested**: Successfully tested in Fat Free CRM with AI lead analysis workflow
- **PunditPolicyTool**: Security-first authorization verification with Pundit integration
  - ✅ **Production-tested**: 21/21 test scenarios passed in Fat Free CRM with real business data
- **ActiveRecordScopeTool**: Business-focused database querying with secure scope execution
  - ✅ **Production-tested**: 5/5 test scenarios passed with 122 real CRM leads and 20+ business scopes
- **ActionMailerTool**: Professional email communication using Rails ActionMailer templates
  - ✅ **Production-ready**: 5/5 security tests passed with comprehensive business email scenarios
- **Production-Ready Configuration**: Complete working Rails initializer template
- **Updated Documentation**: Comprehensive guides and working examples
- **Test Rake Task**: Simple integration verification task
- **Migration Guide**: Step-by-step upgrade instructions

### ⚠️ Changed
- **OpenRouter Support**: Temporarily removed due to library compatibility issues
- **LLMInterface**: Now requires explicit provider and model parameters
- **Configuration**: Updated parameter names and validation
- **Dependencies**: Reduced external library dependencies

### 📚 Documentation
- Updated `README.md` with working configuration examples
- Enhanced `docs/RAILS_INTEGRATION.md` with complete setup guide  
- New `docs/OPENAI_INTEGRATION_UPDATE.md` with migration details
- Updated Rails generator template with working configuration

### 🧪 Testing
- ✅ Full Rails integration tested and verified
- ✅ LLM task execution with variable resolution
- ✅ Tool registry and advanced tools registration
- ✅ Background job integration ready for production

---

## [v1.0.0] - Initial Release

### Features
- Core workflow engine with sequential task execution
- LLM integration via Raix and OpenRouter
- Rails integration with Active Job support
- Tool registry system with extensible architecture
- Variable resolution with `${...}` syntax
- DirectHandlerTask for Ruby code execution
- Advanced tools: file search, web search, markdown generation
- Cron scheduling with CronTool
- MCP (Model Context Protocol) integration
- Comprehensive error handling and validation

### Tools Included
- **Vector Store Tools**: Create, manage, and search vector stores
- **File Upload Tools**: Upload and process files via OpenAI API
- **Web Search Tools**: Real-time web search capabilities  
- **Markdown Tools**: AI-powered markdown generation and editing
- **Cron Tools**: Task scheduling with rufus-scheduler
- **MCP Tools**: Model Context Protocol integration
- **ActionCableTool**: Real-time UI updates with Turbo Streams and Action Cable

### Rails Integration
- Active Job integration for background processing
- Rails generators for quick setup
- Active Record integration for data persistence
- Rails-native error handling and logging 