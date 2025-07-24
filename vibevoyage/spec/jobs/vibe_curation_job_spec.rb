
require 'rails_helper'

RSpec.describe VibeCurationJob, type: :job do
  let(:user) { create(:user) }
  let(:vibe_input) { "Quiero un sábado bohemio en Madrid, con arte y café" }

  it "se encola correctamente" do
    expect {
      VibeCurationJob.perform_later(user_id: user.id, vibe_input: vibe_input)
    }.to have_enqueued_job(VibeCurationJob)
  end

  it "ejecuta el workflow y retorna resultado simulado" do
    # Mockear el workflow para evitar llamadas reales a APIs y LLM
    workflow_double = double('VibeVoyageWorkflow', run: { success: true, narrative: "Narrativa generada" })
    stub_const('Workflows::VibeVoyageWorkflow', Class.new do
      def initialize(*); end
    end)
    allow(Workflows::VibeVoyageWorkflow).to receive(:new).and_return(workflow_double)

    result = VibeCurationJob.perform_now(user_id: user.id, vibe_input: vibe_input)
    expect(result[:success]).to eq(true)
    expect(result[:narrative]).to eq("Narrativa generada")
  end
end
