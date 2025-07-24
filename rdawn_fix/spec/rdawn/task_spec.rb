# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Rdawn::Task do
  let(:task) { described_class.new(task_id: '1', name: 'Test Task') }

  it 'initializes with a pending status' do
    expect(task.status).to eq(:pending)
  end

  it 'can be marked as running' do
    task.mark_running
    expect(task.status).to eq(:running)
  end

  it 'can be marked as completed' do
    task.mark_completed({ result: 'success' })
    expect(task.status).to eq(:completed)
    expect(task.output_data).to eq({ result: 'success' })
  end

  it 'can be marked as failed' do
    task.mark_failed('Something went wrong')
    expect(task.status).to eq(:failed)
    expect(task.output_data).to eq({ error: 'Something went wrong' })
  end

  it 'can be converted to a hash' do
    expect(task.to_h).to be_a(Hash)
    expect(task.to_h[:task_id]).to eq('1')
  end
end
