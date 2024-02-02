require 'rails_helper'

RSpec.describe OpenWeatherMap::GeocodeService do
  let(:service) { described_class.new }
  let(:zip_code) { '12345' }
  let(:country_code) { 'US' }

  let(:fake_http_response) do
    instance_double(HTTParty::Response, body: '{"lat":"some_lat","lon":"some_lon"}', code: 200, success?: true)
  end

  describe '#fetch_by_zip' do
    before do
      allow(HTTParty).to receive(:get).and_return(fake_http_response)
    end

    it 'fetches the geolocation using zip and country code' do
      result = service.fetch_by_zip(zip_code, country_code)

      expect(HTTParty).to have_received(:get).with(
        'https://api.openweathermap.org/geo/1.0/zip',
        query: hash_including(zip: "#{zip_code},#{country_code}")
      )

      expect(result).to eq(
        lat: 'some_lat',
        lon: 'some_lon'
      )
    end
  end
end
