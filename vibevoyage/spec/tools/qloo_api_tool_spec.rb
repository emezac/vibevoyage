require 'rails_helper'
require 'httpx'
require_relative '../../app/tools/qloo_api_tool'

describe QlooApiTool do
  describe '.recommendations' do
    let(:params) { { query: 'music', limit: 1 } }

    context 'cuando la respuesta es exitosa (200)' do
      it 'devuelve el cuerpo parseado como hash' do
        fake_response = double('HTTPX::Response', status: 200, body: '{"result": "ok"}')
        allow(HTTPX).to receive(:with).and_return(HTTPX)
        allow(HTTPX).to receive(:get).and_return(fake_response)

        result = QlooApiTool.recommendations(params)
        expect(result).to eq({ 'result' => 'ok' })
      end
    end

    context 'cuando la respuesta es error (401 o 500)' do
      it 'devuelve un hash con el error y el cuerpo' do
        fake_response = double('HTTPX::Response', status: 401, body: 'Unauthorized')
        allow(HTTPX).to receive(:with).and_return(HTTPX)
        allow(HTTPX).to receive(:get).and_return(fake_response)

        result = QlooApiTool.recommendations(params)
        expect(result).to eq({ error: 401, body: 'Unauthorized' })
      end
    end

    context 'cuando ocurre una excepción' do
      it 'devuelve un hash con el mensaje de excepción' do
        allow(HTTPX).to receive(:with).and_raise(StandardError.new('network error'))
        result = QlooApiTool.recommendations(params)
        expect(result).to eq({ error: 'exception', message: 'network error' })
      end
    end
  end
end
