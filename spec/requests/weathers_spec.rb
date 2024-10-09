require 'rails_helper'

RSpec.describe "Weather Forecasts", type: :request do
  describe "GET /index" do
    context "when a valid query is provided" do
      it "displays weather forecast" do
        VCR.use_cassette("valid_weather_query", record: :new_episodes) do
          get weathers_path, params: { q: "90210" }  # Using Beverly Hills ZIP code as a known valid input
          expect(response).to have_http_status(:success)
          expect(response.body).to include('Here is the 3-hour forecast')
          expect(response.body).to include('90210')  # Check for the ZIP code in the response
        end
      end
    end
  end
end
