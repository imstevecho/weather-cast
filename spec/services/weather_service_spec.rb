require 'rails_helper'

RSpec.describe WeatherService do
  let(:geocode_service) { instance_double(GeocodeService) }
  let(:forecast_service) { instance_double(ForecastService) }
  let(:weather_service) { described_class.new(geocode_service: geocode_service, forecast_service: forecast_service) }

  let(:fake_forecast_data) { [{ date: 1633640400, temp: 73.0, temp_min: 70.0, temp_max: 76.0 }] }

  before do
    allow(geocode_service).to receive(:coords_by_zipcode).and_return({data: { lat: 40.7128, lon: -74.0060, zip: '10007'}, is_from_cache: false })
    allow(geocode_service).to receive(:coords_by_address).and_return({data: { lat: 40.7128, lon: -74.0060, zip: '10007'}, is_from_cache: false })
    allow(forecast_service).to receive(:with_lat_lon).and_return(fake_forecast_data)
  end

  describe '#fetch_weather' do
    context 'when coordinates are found' do
      it 'fetches the weather data' do
        result = weather_service.fetch_weather('10007')
        expect(result[:forecast_data]).to eq(fake_forecast_data)
      end

      it 'sets is_from_cache to false if not cached' do
        result = weather_service.fetch_weather('10007')
        expect(result[:is_from_cache]).to eq(false)
      end

      it 'sets is_from_cache to true if cached' do
        allow(CachingService).to receive(:fetch).and_return({data: fake_forecast_data, is_from_cache: true})

        result = weather_service.fetch_weather('10007')

        expect(result[:is_from_cache]).to eq(true)
      end
    end

    context 'when coordinates are not found' do
      before do
        allow(geocode_service).to receive(:coords_by_zipcode).and_return(nil)
      end

      it 'returns an error message' do
        expect { weather_service.fetch_weather('10007') }.to raise_error(StandardError)
      end
    end
  end
end
