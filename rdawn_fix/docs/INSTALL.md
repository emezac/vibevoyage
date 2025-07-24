# Installation Guide for rdawn

This guide provides step-by-step instructions for installing and setting up the rdawn framework.

## Table of Contents

- [System Requirements](#system-requirements)
- [Installation Methods](#installation-methods)
- [API Key Setup](#api-key-setup)
- [Basic Configuration](#basic-configuration)
- [Verification](#verification)
- [Rails Integration](#rails-integration)
- [Troubleshooting](#troubleshooting)
- [Advanced Installation](#advanced-installation)

## System Requirements

### Ruby Version
- **Ruby 3.0.0 or higher** (recommended: Ruby 3.1+)
- **Bundler 2.0+** for dependency management

### Operating Systems
- **macOS** (tested on macOS 12+)
- **Linux** (Ubuntu 20.04+, CentOS 8+, etc.)
- **Windows** (via WSL2 recommended)

### Dependencies
- **OpenAI API Key** (required for LLM features)
- **Internet connection** (for web search and API calls)

### Optional Dependencies
- **Rails 7.0+** (for Rails integration)
- **PostgreSQL** (for vector stores in production)
- **Redis** (for job queuing)

## Installation Methods

### Method 1: RubyGems (Recommended)

```bash
# Install the latest stable version
gem install rdawn

# Or install a specific version
gem install rdawn -v 0.1.0
```

### Method 2: Bundler (For Applications)

Add to your `Gemfile`:

```ruby
# Gemfile
gem 'rdawn'

# For Rails applications
gem 'rdawn'
gem 'raix'  # LLM integration
```

Then install:

```bash
bundle install
```

### Method 3: From Source (Development)

```bash
# Clone the repository
git clone https://github.com/your-org/rdawn.git
cd rdawn

# Install dependencies
bundle install

# Build and install the gem
cd rdawn
gem build rdawn.gemspec
gem install rdawn-*.gem
```

## API Key Setup

### OpenAI API Key (Required)

1. **Get your API key** from [OpenAI Platform](https://platform.openai.com/api-keys)

2. **Set environment variable** (choose one method):

#### Option A: Shell Profile (Recommended)
```bash
# Add to ~/.bashrc, ~/.zshrc, or ~/.profile
export OPENAI_API_KEY="sk-your-actual-openai-api-key-here"

# Reload your shell
source ~/.bashrc  # or ~/.zshrc
```

#### Option B: Environment File
```bash
# Create .env file in your project root
echo "OPENAI_API_KEY=sk-your-actual-openai-api-key-here" > .env
```

#### Option C: Rails Credentials (Rails apps)
```bash
# Edit credentials
EDITOR=nano rails credentials:edit

# Add:
# openai:
#   api_key: sk-your-actual-openai-api-key-here
```

### Alternative Environment Variable Names

rdawn also supports these environment variable names:

```bash
# Primary (recommended)
export OPENAI_API_KEY="sk-your-key"

# Alternative
export RDAWN_LLM_API_KEY="sk-your-key"
```

## Basic Configuration

### Standalone Ruby Application

```ruby
# config/rdawn.rb or at the top of your script
require 'rdawn'
require 'raix'

# Configure Raix for LLM integration
Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(
    api_key: ENV['OPENAI_API_KEY']
  )
end

# Register advanced tools (optional)
Rdawn::Tools.register_advanced_tools(
  api_key: ENV['OPENAI_API_KEY']
)
```

### Rails Application

1. **Add to Gemfile**:
```ruby
# Gemfile
gem 'rdawn'
gem 'raix'
gem 'openai'
```

2. **Create initializer**:
```ruby
# config/initializers/rdawn.rb
Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(
    api_key: ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai&.api_key
  )
end

# Register tools with API key
Rdawn::Tools.register_advanced_tools(
  api_key: ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai&.api_key
)
```

3. **Generate rdawn files** (optional):
```bash
# Generate Rails integration files
rails generate rdawn:install
```

## Verification

### Test Basic Installation

Create a test file `test_rdawn.rb`:

```ruby
#!/usr/bin/env ruby

require 'rdawn'
require 'raix'

puts "🚀 Testing rdawn installation..."

# Test 1: Basic gem loading
begin
  puts "✅ rdawn gem loaded successfully"
  puts "   Version: #{Rdawn::VERSION}"
rescue => e
  puts "❌ Error loading rdawn: #{e.message}"
  exit 1
end

# Test 2: API key configuration
api_key = ENV['OPENAI_API_KEY'] || ENV['RDAWN_LLM_API_KEY']
if api_key
  puts "✅ OpenAI API key found"
else
  puts "⚠️  OpenAI API key not found - LLM features will not work"
end

# Test 3: Basic workflow creation
begin
  workflow = Rdawn::Workflow.new(workflow_id: 'test', name: 'Test Workflow')
  puts "✅ Workflow creation successful"
rescue => e
  puts "❌ Error creating workflow: #{e.message}"
end

# Test 4: Tool registry
begin
  # Test if ToolRegistry is accessible
  Rdawn::ToolRegistry.class
  puts "✅ Tool registry accessible"
rescue => e
  puts "❌ Error accessing tool registry: #{e.message}"
end

# Test 5: Task creation
begin
  task = Rdawn::Task.new(
    task_id: 'test_task',
    name: 'Test Task',
    is_llm_task: false
  )
  puts "✅ Task creation successful"
rescue => e
  puts "❌ Error creating task: #{e.message}"
end

puts "\n🎉 Installation verification complete!"
```

Run the test:

```bash
ruby test_rdawn.rb
```

### Test with Simple Example

```ruby
# simple_test.rb
require 'rdawn'

# Configure
Raix.configure do |config|
  config.openai_client = OpenAI::Client.new(api_key: ENV['OPENAI_API_KEY'])
end

# Create a simple workflow
workflow = Rdawn::Workflow.new(workflow_id: 'hello_world', name: 'Hello World Workflow')

# Add a task
task = Rdawn::Task.new(
  task_id: 'say_hello',
  name: 'Say Hello',
  is_llm_task: true,
  input_data: { prompt: 'Say hello in a friendly way' }
)

workflow.add_task(task)

# Create engine and run
engine = Rdawn::WorkflowEngine.new(
  workflow: workflow,
  llm_interface: Rdawn::LLMInterface.new
)

result = engine.run
puts "Result: #{result}"
```

## Rails Integration

### Generate Rails Files

```bash
# Generate initializer and configuration
rails generate rdawn:install

# This creates:
# - config/initializers/rdawn.rb (with working OpenAI configuration)
# - app/workflows/ (directory for workflow definitions)
# - app/workflows/handlers/ (directory for workflow handlers)
```

### Verify Configuration

After running the generator, your `config/initializers/rdawn.rb` should look like:

```ruby
# config/initializers/rdawn.rb
Rdawn.configure do |config|
  config.llm_api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
  config.llm_model = 'gpt-4o-mini'
  config.llm_provider = 'openai'
end

# Register advanced tools
api_key = ENV['OPENAI_API_KEY'] || Rails.application.credentials.openai_api_key
Rdawn::Tools.register_advanced_tools(api_key: api_key)
```

### Test the Integration

Create a simple rake task to test:

```ruby
# lib/tasks/rdawn_test.rake
namespace :rdawn do
  task test: :environment do
    workflow = Rdawn::Workflow.new(workflow_id: 'test', name: 'Test')
    
    task = Rdawn::Task.new(
      task_id: '1',
      name: 'Test LLM',
      is_llm_task: true,
      input_data: { prompt: 'Say hello!' }
    )
    workflow.add_task(task)
    
    llm_interface = Rdawn::LLMInterface.new(
      provider: :openai,
      api_key: Rdawn.config.llm_api_key,
      model: Rdawn.config.llm_model
    )
    
    agent = Rdawn::Agent.new(workflow: workflow, llm_interface: llm_interface)
    result = agent.run
    
    puts "✅ Rdawn is working!"
    puts "Response: #{result.tasks.values.first.output_data[:llm_response]}"
  end
end
```

Run the test:

```bash
rails rdawn:test
```

### Create Rails-Specific Workflows

```ruby
# app/workflows/user_onboarding_workflow.rb
class UserOnboardingWorkflow < Rdawn::Workflow
  def initialize(user_id:)
    super(workflow_id: "user_onboarding_#{user_id}")
    @user_id = user_id
    setup_tasks
  end

  private

  def setup_tasks
    # Add workflow tasks here
    add_task(Rdawn::Task.new(
      task_id: 'send_welcome_email',
      name: 'Send Welcome Email',
      tool_name: 'email_sender',
      input_data: { user_id: @user_id }
    ))
  end
end
```

## Troubleshooting

### Common Issues

#### 1. Gem Installation Fails

**Error**: `Failed to build gem native extension`

**Solution**:
```bash
# Install build dependencies
# On Ubuntu/Debian:
sudo apt-get install build-essential ruby-dev

# On macOS:
xcode-select --install

# On CentOS/RHEL:
sudo yum groupinstall "Development Tools"
sudo yum install ruby-devel
```

#### 2. OpenAI API Key Not Found

**Error**: `OpenAI API key is required`

**Solution**:
```bash
# Verify environment variable
echo $OPENAI_API_KEY

# Check if it's set correctly
env | grep OPENAI

# Set it properly
export OPENAI_API_KEY="sk-your-key-here"
```

#### 3. Dependency Conflicts

**Error**: `Bundler could not find compatible versions`

**Solution**:
```bash
# Update bundler
gem update bundler

# Clean bundle cache
bundle clean --force

# Install with specific versions
bundle install --full-index
```

#### 4. Network/Proxy Issues

**Error**: `Connection refused` or `SSL errors`

**Solution**:
```bash
# Set proxy (if needed)
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080

# Update SSL certificates
# On macOS:
brew install ca-certificates

# On Ubuntu:
sudo apt-get update && sudo apt-get install ca-certificates
```

#### 5. Ruby Version Issues

**Error**: `Ruby version X.X.X is not supported`

**Solution**:
```bash
# Check Ruby version
ruby -v

# Install correct Ruby version using rbenv
rbenv install 3.1.0
rbenv global 3.1.0

# Or using RVM
rvm install 3.1.0
rvm use 3.1.0 --default
```

### Debug Mode

Enable debug logging:

```ruby
# At the top of your script
ENV['RDAWN_DEBUG'] = 'true'

require 'rdawn'

# This will show detailed logs
```

### Getting Help

1. **Check the logs**: Enable debug mode and check output
2. **Verify dependencies**: Run `bundle list` to see installed gems
3. **Check examples**: Look at `../examples/` for working code
4. **GitHub Issues**: Report bugs at [GitHub Issues](https://github.com/your-org/rdawn/issues)

## Advanced Installation

### Development Setup

```bash
# Clone and setup for development
git clone https://github.com/your-org/rdawn.git
cd rdawn

# Install development dependencies
bundle install

# Run tests
bundle exec rspec

# Start development server (if applicable)
bundle exec rails server
```

### Custom Installation Location

```bash
# Install to custom location
gem install rdawn --install-dir /custom/path

# Add to PATH
export PATH="/custom/path/bin:$PATH"
```

### Docker Installation

```dockerfile
# Dockerfile
FROM ruby:3.1

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV OPENAI_API_KEY=sk-your-key-here

CMD ["ruby", "your_rdawn_app.rb"]
```

### Production Considerations

1. **Environment Variables**: Use secure secret management
2. **Monitoring**: Set up logging and monitoring
3. **Scaling**: Consider job queues for workflows
4. **Security**: Rotate API keys regularly

## Next Steps

After installation:

1. **Read the documentation**: Check out `../docs/README.md`
2. **Try examples**: Run examples from `../examples/`
3. **Build your first workflow**: Start with `../examples/simple_example.rb`
4. **Learn advanced features**: Read `ADVANCED_FEATURES.md`

## Support

- **Documentation**: `../docs/README.md`
- **Examples**: `../examples/`
- **Issues**: GitHub Issues
- **Community**: Discussions tab

---

**Installation complete!** You're ready to start building AI-powered workflows with rdawn. 🚀 