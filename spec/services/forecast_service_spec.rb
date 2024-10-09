require 'rails_helper'

RSpec.describe ForecastService do
  let(:service) { ForecastService.new('US') }
  let(:lat) { 43.8986416 }
  let(:lon) { -79.4509662 }
  let(:cache_key) { "forecast_#{lat}_#{lon}" }

  let(:fake_http_response) do
    instance_double(HTTParty::Response,
                    body: '{"list": [{"dt": 12345, "main": {"temp": 25, "temp_min": 20, "temp_max": 30}}]}', code: 200, success?: true)
  end

  describe '#with_lat_lon' do
    before do
      allow(HTTParty).to receive(:get).and_return(fake_http_response)
    end

    it 'fetches the forecast using latitude and longitude' do
      result = service.with_lat_lon(lat, lon)

      expect(result.first).to include(
        temp: 25,
        temp_min: 20,
        temp_max: 30
      )
      expect(result.first[:date]).to be_a(Time)
      expect(result.first[:description]).to be_nil
      expect(result.first[:icon]).to be_nil
    end
  end
end
