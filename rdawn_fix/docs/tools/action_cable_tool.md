# ActionCableTool Documentation

## Overview

The `ActionCableTool` is a Rails-native tool that enables **real-time UI updates** through Turbo Streams and Action Cable. This tool allows Rdawn agents to send live updates to client interfaces, creating interactive and fluid copilot experiences.

## Key Features

- **Real-time Turbo Stream Updates**: Send live DOM updates to connected clients
- **Action Cable Broadcasting**: Send data to specific channels and users
- **Rails Native Integration**: Deep integration with Rails, Hotwire, and Action Cable
- **Security Aware**: Respects Rails patterns and user contexts
- **Flexible Content**: Support both Rails partials and raw HTML content

## Value Proposition

### Traditional Approach vs. ActionCableTool

**Without ActionCableTool:**
- Agent processes data → Updates database → User refreshes page → Sees changes
- Static, disconnected user experience
- No real-time feedback during long-running operations

**With ActionCableTool:**
- Agent processes data → Updates database → **Instantly updates UI** → User sees live changes
- Dynamic, connected copilot experience  
- Real-time progress indicators and status updates

## Installation & Setup

### Prerequisites

Ensure your Rails app has the required gems:

```ruby
# Gemfile
gem 'turbo-rails'     # For Turbo Streams
gem 'redis'           # For Action Cable (production)
```

### Action Cable Configuration

```ruby
# config/cable.yml
development:
  adapter: async

production:
  adapter: redis
  url: redis://localhost:6379/1
  channel_prefix: myapp_production
```

### Turbo Streams Setup

In your layout:

```erb
<!-- app/views/layouts/application.html.erb -->
<%= turbo_include_tags %>
```

## Tool Registration

The ActionCableTool is automatically registered when Rails loads:

```ruby
# Available tool names:
# - 'action_cable'  (generic name)
# - 'turbo_stream'  (specific to Turbo Streams)
```

## Usage Examples

### Example 1: Real-time Project Status Updates

**Rails View Setup:**
```erb
<!-- app/views/projects/show.html.erb -->
<%= turbo_stream_from @project %>

<div id="project_status">
  <h3>Status: <%= @project.status %></h3>
</div>

<div id="project_progress">
  <!-- Progress updates will appear here -->
</div>
```

**Rdawn Workflow:**
```ruby
# Real-time project analysis workflow
workflow = Rdawn::Workflow.new(
  workflow_id: "analyze_project_#{project.id}",
  name: 'AI Project Analysis'
)

# Step 1: Start analysis and notify user
start_task = Rdawn::Task.new(
  task_id: '1',
  name: 'Notify Analysis Start',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: '${project}',
    target: 'project_status',
    turbo_action: 'replace',
    content: '<h3 class="text-blue-600">🔍 AI Analysis in Progress...</h3>'
  }
)
start_task.next_task_id_on_success = '2'

# Step 2: Perform AI analysis
analysis_task = Rdawn::Task.new(
  task_id: '2',
  name: 'AI Analysis',
  is_llm_task: true,
  input_data: {
    prompt: 'Analyze this project: ${project.description}. Provide status and recommendations.',
    model_params: { max_tokens: 500 }
  }
)
analysis_task.next_task_id_on_success = '3'

# Step 3: Update UI with results
update_task = Rdawn::Task.new(
  task_id: '3',
  name: 'Update Project Status',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: '${project}',
    target: 'project_status',
    turbo_action: 'replace',
    partial: 'projects/analysis_result',
    locals: {
      analysis: '${llm_response}',
      completed_at: Time.current
    }
  }
)

workflow.add_task(start_task)
workflow.add_task(analysis_task)
workflow.add_task(update_task)
```

**Rails Partial:**
```erb
<!-- app/views/projects/_analysis_result.html.erb -->
<div class="bg-green-50 p-4 rounded">
  <h3 class="text-green-800">✅ Analysis Complete</h3>
  <p class="text-sm text-gray-600">Completed at <%= completed_at.strftime('%I:%M %p') %></p>
  <div class="mt-2">
    <%= simple_format(analysis) %>
  </div>
</div>
```

### Example 2: Live Task Progress Updates

**Using Action Cable for Progress Broadcasting:**

```ruby
# Progress notification workflow
progress_task = Rdawn::Task.new(
  task_id: '1',
  name: 'Broadcast Progress',
  tool_name: 'action_cable',
  input_data: {
    action_type: 'broadcast',
    streamable: '${current_user}',
    data: {
      type: 'progress_update',
      message: 'Processing ${step_name}...',
      progress: '${step_number}',
      total_steps: '${total_steps}'
    }
  }
)
```

**JavaScript Client:**
```javascript
// app/javascript/channels/user_channel.js
import consumer from "./consumer"

consumer.subscriptions.create({
  channel: "UserChannel",
  user_id: getCurrentUserId()
}, {
  received(data) {
    if (data.type === 'progress_update') {
      updateProgressBar(data.progress, data.total_steps);
      showProgressMessage(data.message);
    }
  }
});
```

### Example 3: Multi-User Collaboration Updates

**Broadcast to Multiple Users:**
```ruby
collaboration_task = Rdawn::Task.new(
  task_id: '1',
  name: 'Notify Team Members',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: '${project}',
    target: 'team_activity',
    turbo_action: 'prepend',
    partial: 'shared/activity_item',
    locals: {
      user: '${current_user}',
      action: 'AI analysis completed',
      timestamp: Time.current
    }
  }
)
```

## Input Parameters

### Turbo Stream Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action_type` | String | Yes | Must be `'turbo_stream'` or `'render_turbo_stream'` |
| `streamable` | Object/String | Yes | Rails object or channel identifier to stream to |
| `target` | String | Yes | DOM ID of the element to target |
| `turbo_action` | String | No | Turbo action: `'append'`, `'prepend'`, `'replace'`, `'update'`, `'remove'`, `'before'`, `'after'` (default: `'replace'`) |
| `partial` | String | No* | Rails partial path (e.g., `'projects/summary'`) |
| `locals` | Hash | No | Variables to pass to the partial |
| `content` | String | No* | Raw HTML content to render |

*Either `partial` or `content` must be provided.

### Action Cable Broadcast Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `action_type` | String | Yes | Must be `'broadcast'` or `'broadcast_to_channel'` |
| `streamable` | Object/String | No* | Rails object or channel identifier |
| `channel` | String | No* | Channel class name (e.g., `'NotificationChannel'`) |
| `data` | Hash | Yes | Data to broadcast (must be JSON-serializable) |

*Either `streamable` or `channel` must be provided.

## Response Format

### Success Response

```ruby
{
  success: true,
  message: "Turbo Stream broadcasted successfully",
  details: {
    target: "project_status",
    action: "replace",
    partial: "projects/analysis_result",
    streamable: "Project ID:123"
  },
  executed_at: 2025-07-18 22:15:30 UTC,
  tool: "ActionCableTool"
}
```

### Error Response

```ruby
{
  success: false,
  error: "Missing required parameter: 'target'",
  executed_at: 2025-07-18 22:15:30 UTC,
  tool: "ActionCableTool"
}
```

## Integration with DirectHandlerTask

### Passing Current User Context

```ruby
# Step 1: Setup context with DirectHandlerTask
setup_task = Rdawn::Tasks::DirectHandlerTask.new(
  task_id: '1',
  name: 'Setup Context',
  handler: proc do |input_data, workflow_vars|
    project = Project.find(input_data[:project_id])
    current_user = User.find(input_data[:user_id])
    
    {
      project: project,
      current_user: current_user,
      can_edit: ProjectPolicy.new(current_user, project).update?
    }
  end,
  input_data: {
    project_id: 123,
    user_id: 456
  }
)

# Step 2: Use context in ActionCableTool
update_task = Rdawn::Task.new(
  task_id: '2',
  name: 'Update UI',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: '${project}',
    target: 'project_details',
    turbo_action: 'replace',
    partial: 'projects/details',
    locals: {
      project: '${project}',
      current_user: '${current_user}',
      editable: '${can_edit}'
    }
  }
)
```

## Advanced Patterns

### Conditional UI Updates

```ruby
# Only update UI if user has permission
update_task.condition = proc { |vars| vars[:can_edit] == true }
```

### Error Handling with UI Feedback

```ruby
# Task with failure notification
analysis_task.next_task_id_on_failure = 'error_notification'

error_task = Rdawn::Task.new(
  task_id: 'error_notification',
  name: 'Show Error',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    streamable: '${project}',
    target: 'project_status',
    turbo_action: 'replace',
    content: '<div class="text-red-600">❌ Analysis failed. Please try again.</div>'
  }
)
```

### Progressive Enhancement

```ruby
# Start with loading state
loading_task = Rdawn::Task.new(
  task_id: '1',
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    target: 'content',
    turbo_action: 'replace',
    content: '<div class="animate-pulse">Loading...</div>'
  }
)

# Then show results
result_task = Rdawn::Task.new(
  task_id: '2', 
  tool_name: 'turbo_stream',
  input_data: {
    action_type: 'turbo_stream',
    target: 'content',
    turbo_action: 'replace',
    partial: 'results/show',
    locals: { data: '${processed_data}' }
  }
)
```

## Security Considerations

1. **User Context**: Always pass proper user context to ensure broadcasts respect permissions
2. **Streamable Objects**: Use Rails objects (User, Project) rather than raw strings when possible
3. **Input Validation**: The tool validates all parameters and provides clear error messages
4. **Rails Conventions**: Follows Rails security patterns and conventions

## Dependencies

- **Rails**: Required
- **Turbo (turbo-rails)**: Required for Turbo Stream functionality  
- **Action Cable**: Required for real-time broadcasting
- **Redis**: Recommended for production Action Cable adapter

## Troubleshooting

### Common Issues

1. **"Turbo is required" Error**
   ```ruby
   # Add to Gemfile
   gem 'turbo-rails'
   ```

2. **Broadcasts Not Received**
   - Check Action Cable is running
   - Verify Redis connection in production
   - Ensure client is subscribed to correct channel

3. **Partial Not Found**
   - Verify partial path is correct
   - Check partial exists in `app/views/`
   - Ensure proper naming (`_partial_name.html.erb`)

### Debugging

Enable debug logging:
```ruby
# config/environments/development.rb
Rails.logger.level = :debug

# Will show ActionCableTool registration and execution logs
```

## Best Practices

1. **Use Partials**: Prefer Rails partials over raw HTML for maintainability
2. **Progressive Updates**: Start with loading states, then show results
3. **Error Handling**: Always provide error task alternatives
4. **User Context**: Pass user information for security and personalization
5. **Scoped Streaming**: Use specific objects (User, Project) rather than global channels

## ✅ Production Testing Results

### Fat Free CRM Integration Test

The ActionCableTool has been **successfully tested in Fat Free CRM**, a production-grade Rails CRM application:

#### **Test Scenario: AI-Powered Lead Analysis**
- **Application**: Fat Free CRM (real Rails CRM system)
- **Models Used**: Lead, User (actual CRM entities)
- **Workflow**: 6-task AI lead analysis with real-time updates
- **Data**: Real lead data (Marjorie Leuschke from Wolf LLC)

#### **Features Verified** ✅
- **🎯 Turbo Stream Updates**: DOM updates working with CRM models
- **📡 Action Cable Broadcasting**: User-specific real-time notifications
- **🧠 AI Integration**: OpenAI analysis of actual lead data
- **🔄 Multi-Task Workflows**: Complex business process automation
- **🛡️ Error Resilience**: Graceful handling of missing front-end setup
- **📊 Variable Resolution**: Dynamic data passing between tasks

#### **Business Value Demonstrated**
- **Sales Efficiency**: Instant AI insights on sales leads
- **Real-time Collaboration**: Live team notifications and updates
- **Progressive Enhancement**: Works even without full Turbo setup
- **Native Integration**: Seamless with existing Rails models

**Result**: All ActionCableTool features working perfectly in a real-world Rails application with actual business data and workflows.

---

The ActionCableTool transforms static Rails applications into dynamic, real-time experiences powered by AI agents. 