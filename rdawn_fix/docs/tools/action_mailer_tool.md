# ActionMailerTool Documentation

The `ActionMailerTool` enables AI agents to send **professional, branded emails** using the host application's existing ActionMailer templates, layouts, and delivery infrastructure. This tool ensures that AI-generated communications maintain the same visual consistency and professionalism as human-generated emails.

## 🎯 Why ActionMailerTool is Essential

### Professional Brand Consistency
- **Template Reuse**: Leverages existing HTML email templates and layouts
- **Brand Standards**: Maintains consistent visual identity and messaging
- **Design Quality**: Professional layouts instead of plain text emails
- **Responsive Design**: Mobile-optimized templates work automatically

### Rails Infrastructure Integration
- **ActiveJob Integration**: Asynchronous email delivery with background jobs
- **Delivery Options**: Both immediate and queued email delivery
- **Error Handling**: Comprehensive SMTP and template error management
- **Serialization**: Automatic handling of ActiveRecord objects in parameters

### Business Communication Excellence
- **Context-Aware**: Uses application data to personalize messages
- **Professional Templates**: Rich HTML formatting with images and styling
- **Workflow Integration**: Seamless email notifications in business processes
- **Multi-Format**: Automatic HTML and text versions of emails

## 🔧 Installation and Setup

### 1. Automatic Registration

The ActionMailerTool is automatically registered when Rails loads with ActionMailer:

```ruby
# This happens automatically in Rails
Rdawn::ToolRegistry.register('action_mailer_send', mailer_tool.method(:call))
```

### 2. ActionMailer Configuration

Ensure your Rails application has ActionMailer properly configured:

```ruby
# config/environments/production.rb
Rails.application.configure do
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address:              'smtp.gmail.com',
    port:                 587,
    domain:               'yourcompany.com',
    user_name:            'your-email@yourcompany.com',
    password:             'your-password',
    authentication:       'plain',
    enable_starttls_auto: true
  }
end
```

### 3. ActiveJob Configuration

For background email delivery (recommended):

```ruby
# config/application.rb
config.active_job.queue_adapter = :sidekiq  # or :resque, :delayed_job, etc.
```

## 📋 Input Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `mailer_name` | String | ✅ | ActionMailer class name (e.g., 'ProjectMailer', 'UserMailer') |
| `action_name` | String/Symbol | ✅ | Mailer action method (e.g., 'welcome_email', :project_update) |
| `params` | Hash | ❌ | Parameters for mailer's `.with()` method (can include AR objects) |
| `delivery_method` | String | ❌ | 'deliver_later' (default) or 'deliver_now' |

### Parameter Details

#### `mailer_name`
- Must be a valid ActionMailer class name ending with 'Mailer'
- Case-sensitive and must match the exact class name
- Examples: 'UserMailer', 'ProjectMailer', 'NotificationMailer'

#### `action_name` 
- Name of the public method in the ActionMailer class
- Can be string or symbol
- Must return a Mail object (i.e., call `mail()` method)

#### `params`
- Hash of data passed to the mailer action via `.with()`
- Can include ActiveRecord objects (automatically serialized by ActiveJob)
- Available in mailer as `params[:key]`

#### `delivery_method`
- `'deliver_later'`: Queued for background delivery (recommended)
- `'deliver_now'`: Immediate synchronous delivery

## 📤 Output Format

### Successful Email
```ruby
{
  success: true,
  result: {
    message: "Email enqueued successfully",
    mailer: "ProjectMailer",
    action: "project_update_notification",
    delivery_method: "deliver_later",
    params_count: 3
  },
  metadata: {
    executed_at: "2025-01-18T10:30:00Z",
    delivery_method: "deliver_later",
    active_job_enabled: true
  }
}
```

### Error Response
```ruby
{
  success: false,
  error: "Mailer 'ProjectMailer' not found. Make sure the mailer class exists and is loaded.",
  suggestion: "Check that ProjectMailer is defined in app/mailers/",
  type: "mailer_not_found"
}
```

## 🚀 Usage Examples

### Basic Email Notification

```ruby
# Send a welcome email to a new user
welcome_email = Rdawn::Task.new(
  task_id: '1',
  name: 'Send Welcome Email',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'UserMailer',
    action_name: 'welcome_email',
    params: {
      user: @user,
      company: @user.company
    }
  }
)
```

### CRM Lead Follow-up

```ruby
# Automated follow-up email for hot leads
lead_followup = Rdawn::Task.new(
  task_id: '2',
  name: 'Send Lead Follow-up',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'LeadMailer',
    action_name: 'follow_up_reminder',
    params: {
      lead: @lead,
      sales_rep: @current_user,
      follow_up_date: 2.days.from_now,
      custom_message: 'Thank you for your interest in our services!'
    },
    delivery_method: 'deliver_later'
  }
)
```

### Project Status Update

```ruby
# Notify team members of project milestones
project_notification = Rdawn::Task.new(
  task_id: '3',
  name: 'Project Milestone Notification',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'ProjectMailer',
    action_name: 'milestone_completed',
    params: {
      project: @project,
      milestone: @milestone,
      team_members: @project.team_members,
      completion_date: Date.current
    }
  }
)
```

### Order Confirmation

```ruby
# E-commerce order confirmation
order_confirmation = Rdawn::Task.new(
  task_id: '4',
  name: 'Send Order Confirmation',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'OrderMailer',
    action_name: 'confirmation_email',
    params: {
      order: @order,
      customer: @order.customer,
      order_items: @order.line_items,
      shipping_address: @order.shipping_address
    },
    delivery_method: 'deliver_now'  # Immediate confirmation
  }
)
```

## 🔄 Workflow Integration

### AI-Powered Customer Onboarding

```ruby
# Multi-step onboarding workflow with email communications
onboarding_workflow = Rdawn::Workflow.new(
  workflow_id: 'customer_onboarding',
  name: 'AI-Powered Customer Onboarding'
)

# Step 1: Welcome email with account setup
welcome_task = Rdawn::Task.new(
  task_id: '1',
  name: 'Send Welcome Email',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'CustomerMailer',
    action_name: 'welcome_email',
    params: {
      customer: '${current_user}',
      account_type: '${signup_params.account_type}'
    }
  }
)

# Step 2: AI generates personalized getting started guide
personalization_task = Rdawn::Task.new(
  task_id: '2',
  name: 'Generate Personalized Guide',
  is_llm_task: true,
  input_data: {
    prompt: "Create a personalized getting started guide for ${current_user.name} 
    who signed up for ${signup_params.account_type} account. 
    Include specific features and benefits relevant to their industry: ${current_user.industry}",
    model_params: { max_tokens: 1000, temperature: 0.7 }
  }
)

# Step 3: Send personalized guide via email
guide_delivery = Rdawn::Task.new(
  task_id: '3',
  name: 'Send Personalized Guide',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'CustomerMailer',
    action_name: 'getting_started_guide',
    params: {
      customer: '${current_user}',
      personalized_content: '${task_2.output.content}',
      industry: '${current_user.industry}'
    }
  }
)

workflow.add_task(welcome_task)
workflow.add_task(personalization_task)  
workflow.add_task(guide_delivery)
```

### CRM Sales Pipeline Automation

```ruby
# Automated sales follow-up with lead scoring
sales_automation = Rdawn::Workflow.new(
  workflow_id: 'sales_followup',
  name: 'AI Sales Follow-up Automation'
)

# Step 1: Analyze lead behavior and score
lead_analysis = Rdawn::Task.new(
  task_id: '1',
  name: 'Analyze Lead Engagement',
  tool_name: 'active_record_scope',
  input_data: {
    model_name: 'Lead',
    scopes: [
      { name: 'hot_leads' },
      { name: 'requiring_followup' }
    ]
  }
)

# Step 2: AI generates personalized follow-up content
content_generation = Rdawn::Task.new(
  task_id: '2',
  name: 'Generate Follow-up Content',
  is_llm_task: true,
  input_data: {
    prompt: "Based on this lead data: ${task_1.output.results}
    
    Generate personalized follow-up email content that:
    1. References their specific interests and engagement
    2. Addresses their industry pain points
    3. Includes relevant case studies or testimonials
    4. Has a clear, compelling call-to-action
    
    Keep the tone professional but friendly.",
    model_params: { max_tokens: 800, temperature: 0.8 }
  }
)

# Step 3: Send personalized follow-up emails
followup_delivery = Rdawn::Task.new(
  task_id: '3',
  name: 'Send Personalized Follow-ups',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'LeadMailer',
    action_name: 'personalized_followup',
    params: {
      leads: '${task_1.output.results}',
      personalized_content: '${task_2.output.content}',
      sales_rep: '${current_user}'
    }
  }
)

workflow.add_task(lead_analysis)
workflow.add_task(content_generation)
workflow.add_task(followup_delivery)
```

### Real-time Workflow with Notifications

```ruby
# Combine ActionMailerTool with ActionCableTool for real-time + email notifications
notification_workflow = Rdawn::Workflow.new(
  workflow_id: 'dual_notification',
  name: 'Real-time + Email Notifications'
)

# Step 1: Send real-time UI notification
realtime_notification = Rdawn::Task.new(
  task_id: '1',
  name: 'Real-time Dashboard Update',
  tool_name: 'turbo_stream',
  input_data: {
    target: 'notifications',
    turbo_action: 'append',
    partial: 'shared/notification',
    locals: {
      message: 'New high-priority lead assigned to you',
      lead: '${lead}',
      urgency: 'high'
    }
  }
)

# Step 2: Send comprehensive email with details
email_notification = Rdawn::Task.new(
  task_id: '2',
  name: 'Detailed Email Notification',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'LeadMailer',
    action_name: 'high_priority_assignment',
    params: {
      lead: '${lead}',
      assigned_to: '${current_user}',
      priority_score: '${lead.priority_score}',
      deadline: '${lead.follow_up_date}'
    }
  }
)

workflow.add_task(realtime_notification)
workflow.add_task(email_notification)
```

## 📧 Creating ActionMailer Classes

### Example: CRM Lead Mailer

```ruby
# app/mailers/lead_mailer.rb
class LeadMailer < ApplicationMailer
  default from: 'sales@yourcompany.com'

  def follow_up_reminder
    @lead = params[:lead]
    @sales_rep = params[:sales_rep]
    @follow_up_date = params[:follow_up_date]
    @custom_message = params[:custom_message]

    mail(
      to: @sales_rep.email,
      cc: @lead.owner.email,
      subject: "Follow-up Required: #{@lead.company} - #{@lead.full_name}"
    )
  end

  def high_priority_assignment
    @lead = params[:lead]
    @assigned_to = params[:assigned_to]
    @priority_score = params[:priority_score]
    @deadline = params[:deadline]

    mail(
      to: @assigned_to.email,
      subject: "High Priority Lead Assignment: #{@lead.company}"
    )
  end

  def personalized_followup
    @leads = params[:leads]
    @personalized_content = params[:personalized_content]
    @sales_rep = params[:sales_rep]

    # Send to each lead individually
    @leads.each do |lead|
      @lead = lead
      mail(
        to: lead.email,
        from: @sales_rep.email,
        subject: "Following up on your interest - #{lead.company}"
      ).deliver_later
    end
  end
end
```

### Example: Email Templates

```erb
<!-- app/views/lead_mailer/follow_up_reminder.html.erb -->
<%= content_for :title, "Follow-up Required" %>

<div class="email-container">
  <div class="header">
    <h1>Follow-up Reminder</h1>
  </div>

  <div class="content">
    <p>Hi <%= @sales_rep.first_name %>,</p>
    
    <p>This is a reminder to follow up with your lead:</p>
    
    <div class="lead-details">
      <h3><%= @lead.full_name %></h3>
      <p><strong>Company:</strong> <%= @lead.company %></p>
      <p><strong>Rating:</strong> <%= @lead.rating %>/5</p>
      <p><strong>Source:</strong> <%= @lead.source.humanize %></p>
      <p><strong>Follow-up Date:</strong> <%= @follow_up_date.strftime('%B %d, %Y') %></p>
    </div>

    <% if @custom_message.present? %>
      <div class="custom-message">
        <h4>Custom Message:</h4>
        <p><%= simple_format(@custom_message) %></p>
      </div>
    <% end %>

    <div class="actions">
      <%= link_to "View Lead", lead_url(@lead), class: "btn btn-primary" %>
      <%= link_to "Update Status", edit_lead_url(@lead), class: "btn btn-secondary" %>
    </div>
  </div>

  <div class="footer">
    <p>This email was generated automatically by your CRM system.</p>
  </div>
</div>
```

## 🔒 Security and Error Handling

### Security Best Practices

```ruby
# ✅ GOOD: Use specific mailer classes
{
  mailer_name: 'UserMailer',  # Specific, expected mailer
  action_name: 'welcome_email',
  params: { user: @user }
}

# ❌ BAD: Don't use generic or system mailers
{
  mailer_name: 'SystemMailer',  # Too generic
  action_name: 'execute_code',  # Dangerous method name
  params: { code: 'User.delete_all' }  # Never pass executable code
}
```

### Parameter Sanitization

```ruby
# ✅ GOOD: Use ActiveRecord objects and safe data
{
  mailer_name: 'LeadMailer',
  action_name: 'follow_up',
  params: {
    lead: Lead.find(params[:lead_id]),  # AR object, safely loaded
    message: params[:message].strip,    # Sanitized input
    user: current_user                  # Authenticated user
  }
}

# ❌ BAD: Don't pass unsanitized user input directly
{
  params: {
    raw_html: params[:user_input],  # Potential XSS
    sql_query: params[:custom_sql]  # SQL injection risk
  }
}
```

### Error Handling Patterns

```ruby
# Robust error handling in workflows
email_task = Rdawn::Task.new(
  task_id: 'email_notification',
  name: 'Send Email Notification',
  tool_name: 'action_mailer_send',
  input_data: {
    mailer_name: 'UserMailer',
    action_name: 'notification',
    params: { user: '${user}', message: '${ai_message}' }
  },
  error_handling: {
    on_failure: 'log_and_continue',
    fallback_task: 'send_sms_notification'
  }
)
```

### Common Error Scenarios

1. **Mailer Not Found**
   ```ruby
   # Error: Mailer 'NonExistentMailer' not found
   # Solution: Verify mailer class exists in app/mailers/
   ```

2. **Action Not Found**
   ```ruby
   # Error: Action 'missing_action' does not exist
   # Solution: Check available actions in the mailer class
   ```

3. **Template Missing**
   ```ruby
   # Error: Email template error: Missing template
   # Solution: Create corresponding view template in app/views/mailer_name/
   ```

4. **SMTP Configuration**
   ```ruby
   # Error: SMTP authentication failed
   # Solution: Check ActionMailer configuration and credentials
   ```

## ⚙️ Production Considerations

### Performance Optimization
- **Background Jobs**: Always use `deliver_later` for production
- **Queue Management**: Monitor email queue length and processing times
- **Template Caching**: Enable view caching for email templates
- **Batch Processing**: Group related emails to reduce overhead

### Email Deliverability
- **SPF/DKIM Setup**: Configure proper email authentication
- **Reputation Management**: Monitor sender reputation and bounce rates
- **Content Quality**: Use well-designed templates and avoid spam triggers
- **List Management**: Implement proper unsubscribe mechanisms

### Monitoring and Analytics
- **Delivery Tracking**: Monitor email delivery success rates
- **Error Logging**: Log all email failures with detailed context
- **Performance Metrics**: Track email generation and delivery times
- **Business Metrics**: Monitor email engagement and conversion rates

### Scaling Considerations
- **Queue Workers**: Scale background job workers based on email volume
- **Template Optimization**: Optimize email templates for fast rendering
- **Database Queries**: Efficient data loading in mailer actions
- **CDN Usage**: Host email assets (images, CSS) on CDN

## 🧪 Testing the ActionMailerTool

### Basic Functionality Test

```ruby
# Test script for ActionMailerTool
mailer_tool = Rdawn::Rails::Tools::ActionMailerTool.new

# Test successful email sending
result = mailer_tool.call({
  mailer_name: 'UserMailer',
  action_name: 'welcome_email',
  params: {
    user: User.first,
    company: User.first.company
  },
  delivery_method: 'deliver_later'
})

puts "Success: #{result[:success]}"
puts "Message: #{result[:result][:message]}" if result[:success]
```

### Integration Test with ActionMailer TestHelper

```ruby
# In RSpec or similar testing framework
require 'rails_helper'

RSpec.describe Rdawn::Rails::Tools::ActionMailerTool do
  include ActionMailer::TestHelper

  let(:user) { create(:user) }
  let(:mailer_tool) { described_class.new }

  it 'enqueues welcome email successfully' do
    expect {
      mailer_tool.call({
        mailer_name: 'UserMailer',
        action_name: 'welcome_email',
        params: { user: user }
      })
    }.to have_enqueued_mail(UserMailer, :welcome_email).with(user: user)
  end

  it 'sends email immediately when requested' do
    expect {
      mailer_tool.call({
        mailer_name: 'UserMailer',
        action_name: 'welcome_email',
        params: { user: user },
        delivery_method: 'deliver_now'
      })
    }.to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
```

## 🎯 Business Benefits

### For Sales Teams
- **Automated Follow-ups**: Consistent, professional lead nurturing
- **Personalized Outreach**: AI-generated content with brand templates
- **Pipeline Notifications**: Real-time alerts for high-priority leads

### For Customer Success
- **Onboarding Sequences**: Automated welcome and setup emails
- **Engagement Campaigns**: Targeted messages based on user behavior  
- **Support Communications**: Professional ticket updates and resolutions

### For Marketing
- **Campaign Automation**: Triggered emails based on user actions
- **Content Distribution**: Newsletter and announcement delivery
- **A/B Testing**: Template variations for optimization

### for Operations
- **System Notifications**: Professional alerts for system events
- **Report Distribution**: Automated business report delivery
- **Compliance Communications**: Audit trails and regulatory notices

---

## 🎯 Conclusion

The **ActionMailerTool** transforms AI email communication from basic text messages into **professional, branded experiences** that maintain consistency with your application's visual identity. By leveraging Rails' robust email infrastructure, it enables:

- **🎨 Brand Consistency**: Professional templates and layouts maintained automatically
- **📈 Business Integration**: Seamless workflow notifications and customer communications  
- **⚡ Performance**: Background job processing with ActiveJob integration
- **🛡️ Reliability**: Comprehensive error handling and SMTP management
- **🔄 Workflow Power**: Perfect integration with other Rdawn tools for complete automation

**Your AI agents now send emails like professional marketing teams, not robots!** 🚀 