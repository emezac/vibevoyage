# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::Workflow do
  let(:workflow) { described_class.new(workflow_id: '1', name: 'Test Workflow') }
  let(:task) { Rdawn::Task.new(task_id: '1', name: 'Test Task') }

  it 'can add a task' do
    workflow.add_task(task)
    expect(workflow.get_task('1')).to eq(task)
  end
end
