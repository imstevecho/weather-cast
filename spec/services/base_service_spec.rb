require 'rails_helper'

RSpec.describe OpenWeatherMap::BaseService do
  let(:base_uri) { 'https://api.openweathermap.org/data/2.5' }
  let(:service) { described_class.new(base_uri) }

  describe '#fetch' do
    let(:fake_response) do
      instance_double(HTTParty::Response, body: '{}', code: 200, success?: true)
    end

    before do
      allow(HTTParty).to receive(:get).and_return(fake_response)
    end

    it 'makes a GET request to the given path with default options' do
      # Invoke the fetch method, so the internal HTTParty.get is called
      service.fetch('/some_path')

      expect(HTTParty).to have_received(:get).with(
        "#{base_uri}/some_path",
        query: hash_including(
          appid: ENV['OPENWEATHER_API_KEY'],
          units: ENV['OPENWEATHER_UNITS'],
          id: ENV['OPENWEATHER_API_ID']
        )
      )
    end

    it 'raises an error when the response is not successful' do
      allow(fake_response).to receive(:success?).and_return(false)

      expect { service.fetch('/some_path') }.to raise_error('API Error')
    end
  end
end
