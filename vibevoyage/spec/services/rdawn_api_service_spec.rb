require 'rails_helper'

describe RdawnApiService do
  describe '.qloo_recommendations' do
    it 'invoca la herramienta QlooApiTool vía Rdawn y retorna datos' do
      allow(Rdawn::ToolRegistry).to receive(:execute).with('qloo_api', hash_including(interests: anything, city: anything)).and_return({ 'recommendations' => ['Museo', 'Teatro'] })
      result = described_class.qloo_recommendations(interests: ['arte'], city: 'Madrid')
      expect(result['recommendations']).to include('Museo')
    end
  end

  describe '.google_places' do
    it 'invoca la herramienta MapsApiTool vía Rdawn y retorna datos' do
      allow(Rdawn::ToolRegistry).to receive(:execute).with('maps_api', hash_including(query: anything)).and_return({ 'results' => [{ 'name' => 'Parque' }] })
      result = described_class.google_places(query: 'Madrid')
      expect(result['results'].first['name']).to eq('Parque')
    end
  end
end
