require 'rails_helper'
require 'httpx'
require 'json'
require_relative '../../app/tools/maps_api_tool'

describe MapsApiTool do
  describe '.search_places' do
    let(:params) { { query: 'Museo del Prado, Madrid' } }

    context 'cuando la API responde exitosamente' do
      it 'devuelve los resultados parseados' do
        response_double = double('HTTPX::Response', status: 200, body: '{"results":[{"name":"Museo del Prado"}]}' )
        allow(HTTPX).to receive(:with).and_return(HTTPX)
        allow(HTTPX).to receive(:get).and_return(response_double)

        result = MapsApiTool.search_places(params)
        expect(result).to eq({ 'results' => [{ 'name' => 'Museo del Prado' }] })
      end
    end

    context 'cuando la API responde con error' do
      it 'devuelve el error y el cuerpo' do
        response_double = double('HTTPX::Response', status: 401, body: 'Unauthorized')
        allow(HTTPX).to receive(:with).and_return(HTTPX)
        allow(HTTPX).to receive(:get).and_return(response_double)

        result = MapsApiTool.search_places(params)
        expect(result).to eq({ error: 401, body: 'Unauthorized' })
      end
    end

    context 'cuando ocurre una excepción' do
      it 'devuelve el mensaje de excepción' do
        allow(HTTPX).to receive(:with).and_raise(StandardError.new('timeout'))
        result = MapsApiTool.search_places(params)
        expect(result).to eq({ error: 'exception', message: 'timeout' })
      end
    end
  end
end
