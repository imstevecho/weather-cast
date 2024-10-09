class WeathersController < ApplicationController
  def index
    @error = nil
    @forecast = nil

    if params[:q].present?
      geocode_service = GeocodeService.new
      begin
        location_info = geocode_service.coords_by_zipcode(params[:q])

        if location_info[:data]
          forecast_service = ForecastService.new(location_info[:data][:country_code])
          @forecast = forecast_service.with_lat_lon(location_info[:data][:lat], location_info[:data][:lon])
        else
          @error = "Unable to find location information"
        end
      rescue GeocodeService::GeocodingError => e
        @error = "Geocoding error: #{e.message}"
      rescue ForecastService::ForecastError => e
        @error = "Forecast error: #{e.message}"
      rescue StandardError => e
        @error = "An unexpected error occurred: #{e.message}"
      end
    end
  end
end
