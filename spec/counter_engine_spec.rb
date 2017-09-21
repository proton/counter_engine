require 'spec_helper'

describe CounterEngine do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  describe 'counter engine' do
    let(:app) do
      Rack::Builder.new do
        use CounterEngine, stats_path: '/stats.json'
        run SimpleApp.new
      end
    end

    subject { JSON.parse(get('/stats.json').body, symbolize_names: true) }

    context 'without requests' do
      it 'should have zero visits' do
        expect(subject[:unique]).to eq(0)
        expect(subject[:all]).to eq(0)
      end
    end
  end

  # тут место для shared examples
  # context: разные конфигурации
  # TODO: чистка базы
end