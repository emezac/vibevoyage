#!/usr/bin/env ruby
# frozen_string_literal: true

# Rails Integration Demo for rdawn
# This demonstrates how rdawn would be used in a Rails application

puts "🚀 Rdawn Rails Integration Demo"
puts "=" * 50

# Example 1: Basic workflow configuration
puts "\n1. Basic Workflow Configuration"
puts "-" * 30

workflow_data = {
  workflow_id: 'user_onboarding',
  name: 'User Onboarding Workflow',
  tasks: {
    'welcome_task' => {
      type: 'direct_handler',
      name: 'Send Welcome Email',
      handler: 'UserOnboarding#send_welcome_email',
      input_data: { user_id: '${user_id}' },
      next_task_id_on_success: 'setup_task'
    },
    'setup_task' => {
      type: 'direct_handler',
      name: 'Setup User Account',
      handler: 'UserOnboarding#setup_account',
      input_data: { user_id: '${user_id}' },
      next_task_id_on_success: 'ai_personalization'
    },
    'ai_personalization' => {
      type: 'llm',
      name: 'Generate Personalized Welcome Message',
      input_data: {
        prompt: 'Generate a personalized welcome message for user ${user.name} with interests: ${user.interests}',
        model_params: { temperature: 0.8, max_tokens: 200 }
      },
      next_task_id_on_success: 'save_message'
    },
    'save_message' => {
      type: 'direct_handler',
      name: 'Save Personalized Message',
      handler: 'UserOnboarding#save_personalized_message',
      input_data: { 
        user_id: '${user_id}',
        message: '${ai_personalization.llm_response}'
      }
    }
  }
}

puts "Workflow Structure:"
puts "- #{workflow_data[:tasks].keys.count} tasks"
puts "- Tasks: #{workflow_data[:tasks].keys.join(', ')}"

# Example 2: LLM Configuration
puts "\n2. LLM Configuration"
puts "-" * 30

llm_config = {
  api_key: 'your_api_key_here',
  model: 'gpt-4o-mini',
  provider: 'openrouter'
}

puts "LLM Config: #{llm_config}"

# Example 3: Workflow execution context
puts "\n3. Workflow Execution Context"
puts "-" * 30

initial_input = {
  user_id: 123,
  user: {
    name: 'John Doe',
    email: 'john@example.com',
    interests: ['technology', 'AI', 'programming']
  }
}

user_context = {
  current_user_id: 456,
  environment: 'production',
  timestamp: Time.now
}

puts "Initial Input: #{initial_input}"
puts "User Context: #{user_context}"

# Example 4: Rails controller integration
puts "\n4. Rails Controller Integration Example"
puts "-" * 30

controller_code = <<~RUBY
  # app/controllers/users_controller.rb
  class UsersController < ApplicationController
    def onboard
      user = User.find(params[:id])
      
      # Define the workflow data
      workflow_data = {
        workflow_id: "user_onboarding_\#{user.id}",
        name: 'User Onboarding',
        tasks: {
          'welcome_task' => {
            type: 'direct_handler',
            name: 'Send Welcome Email',
            handler: 'UserOnboarding#send_welcome_email',
            input_data: { user_id: user.id }
          }
        }
      }
      
      # Execute workflow in background
      Rdawn::Rails::WorkflowJob.run_workflow_later(
        workflow_data: workflow_data,
        llm_config: {
          api_key: ENV['RDAWN_LLM_API_KEY'],
          model: 'gpt-4o-mini'
        },
        initial_input: { user_id: user.id },
        user_context: { current_user_id: current_user.id }
      )
      
      render json: { message: 'Onboarding workflow started' }
    end
  end
RUBY

puts controller_code

# Example 5: Workflow handler
puts "\n5. Workflow Handler Example"
puts "-" * 30

handler_code = <<~RUBY
  # app/workflows/handlers/user_onboarding.rb
  class UserOnboarding
    def send_welcome_email(input_data, workflow_variables)
      user = User.find(input_data['user_id'])
      
      # Send welcome email
      UserMailer.welcome_email(user).deliver_now
      
      # Return success data
      {
        success: true,
        user: user.attributes,
        email_sent: true,
        timestamp: Time.current
      }
    end
    
    def setup_account(input_data, workflow_variables)
      user = User.find(input_data['user_id'])
      
      # Setup user account
      user.update!(
        onboarded: true,
        setup_completed_at: Time.current
      )
      
      {
        success: true,
        user: user.attributes,
        setup_completed: true
      }
    end
    
    def save_personalized_message(input_data, workflow_variables)
      user = User.find(input_data['user_id'])
      message = input_data['message']
      
      # Save personalized message
      user.messages.create!(
        content: message,
        message_type: 'welcome',
        created_at: Time.current
      )
      
      {
        success: true,
        message_saved: true,
        message_content: message
      }
    end
  end
RUBY

puts handler_code

# Example 6: Generator usage
puts "\n6. Generator Usage"
puts "-" * 30

generator_commands = <<~BASH
  # Install rdawn in your Rails app
  rails generate rdawn:install
  
  # This creates:
  # - config/initializers/rdawn.rb
  # - app/workflows/
  # - app/workflows/handlers/
  
  # Set up environment variables
  export RDAWN_LLM_API_KEY=your_api_key_here
  export RDAWN_LLM_MODEL=gpt-4o-mini
  
  # Start your Rails server
  rails server
BASH

puts generator_commands

# Example 7: Configuration in Rails
puts "\n7. Rails Configuration Example"
puts "-" * 30

config_code = <<~RUBY
  # config/initializers/rdawn.rb
  require 'rdawn/rails'
  
  # Configure rdawn
  Rdawn.configure do |config|
    config.llm_api_key = ENV['RDAWN_LLM_API_KEY']
    config.llm_model = ENV['RDAWN_LLM_MODEL'] || 'gpt-4o-mini'
    config.llm_provider = 'openrouter'
  end
  
  # Configure Rails-specific settings
  Rdawn::Rails.configure do |config|
    config.default_queue_adapter = :sidekiq
    config.default_queue_name = :rdawn
    config.enable_active_job_integration = true
  end
RUBY

puts config_code

puts "\n🎉 Rails Integration Demo Complete!"
puts "=" * 50
puts "This demonstrates how rdawn seamlessly integrates with Rails applications"
puts "for building powerful, Rails-native AI agent workflows." 