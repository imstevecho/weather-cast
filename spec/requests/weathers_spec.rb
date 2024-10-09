require 'rails_helper'

RSpec.describe "Weather Forecasts", type: :request do
  describe "GET /index" do
    let(:weather_service) { instance_double("WeatherService") }

    before do
      allow(WeatherService).to receive(:new).and_return(weather_service)
    end

    context "when a valid query is provided" do
      before do
        allow(weather_service).to receive(:fetch_weather).and_return(forecast_data: [{date: Time.zone.now, temp: '70', temp_max: '75', temp_min: '65'}], is_from_cache: false, zip: '12345')
      end

      it "displays weather forecast" do
        get weathers_path, params: { q: 'valid_query' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Here is the 3-hour forecast')
      end
    end

  end
end
