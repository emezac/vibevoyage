require 'rails_helper'

RSpec.describe RdawnApiService do
  # IMPORTANTE: Limpiar cualquier stub previo del servicio
  before(:each) do
    # Restaurar el método original si existe
    if described_class.singleton_class.method_defined?(:qloo_recommendations)
      RSpec::Mocks.space.proxy_for(described_class).reset
    end
    
    allow(Rails).to receive(:logger).and_return(Logger.new(nil))
  end

  describe '.qloo_recommendations' do
    context 'cuando la llamada es exitosa' do
      it 'retorna datos de la API' do
        # Mock de ToolRegistry, NO del servicio
        mock_response = {
          success: true,
          data: {
            'results' => {
              'entities' => [
                { 'name' => 'Museo del Prado', 'type' => 'museum' }
              ]
            }
          }
        }
        
        allow(Rdawn::ToolRegistry).to receive(:execute)
          .with('qloo_api', hash_including(interests: ['arte'], city: 'Madrid'))
          .and_return(mock_response)

        result = described_class.qloo_recommendations(
          interests: ['arte'],
          city: 'Madrid'
        )

        expect(result).to eq(mock_response)
        expect(result[:data]['results']['entities']).not_to be_empty
      end
    end

    context 'cuando el resultado no es un Hash' do
      it 'retorna error' do
        allow(Rdawn::ToolRegistry).to receive(:execute)
          .with('qloo_api', anything)
          .and_return("string no válido")

        result = described_class.qloo_recommendations(
          interests: ['arte'],
          city: 'Madrid'
        )

        expect(result[:success]).to eq(false)
        expect(result[:error]).to include("Unexpected result format")
      end
    end

    context 'cuando hay una excepción' do
      it 'maneja el error correctamente' do
        allow(Rdawn::ToolRegistry).to receive(:execute)
          .and_raise(StandardError.new("Error de API"))

        result = described_class.qloo_recommendations(
          interests: ['arte'],
          city: 'Madrid'
        )

        expect(result[:success]).to eq(false)
        expect(result[:error]).to include("Tool execution failed")
      end
    end
  end

  describe '.google_places' do
    context 'cuando la llamada es exitosa' do
      it 'retorna datos de lugares' do
        mock_response = {
          success: true,
          data: {
            'results' => [
              { 'name' => 'Parque del Retiro', 'address' => 'Madrid' }
            ]
          }
        }
        
        allow(Rdawn::ToolRegistry).to receive(:execute)
          .with('maps_api', hash_including(query: 'Madrid'))
          .and_return(mock_response)

        result = described_class.google_places(query: 'Madrid')

        expect(result).to eq(mock_response)
        expect(result[:data]['results']).not_to be_empty
      end
    end
  end
end