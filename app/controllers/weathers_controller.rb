class WeathersController < ApplicationController
  def index
    if params[:q].present?
      geocode_service = GeocodeService.new
      begin
        location_info = geocode_service.coords_by_zipcode(params[:q])

        if location_info[:data]
          forecast_service = ForecastService.new(location_info[:data][:country_code])
          @forecast_data = forecast_service.with_lat_lon(location_info[:data][:lat], location_info[:data][:lon])
          @zip = location_info[:data][:zip]
          @is_from_cache = location_info[:is_from_cache]
        else
          flash[:error] = "Unable to find location information"
        end
      rescue GeocodeService::GeocodingError => e
        flash[:error] = "Geocoding error: #{e.message}"
      rescue ForecastService::ForecastError => e
        flash[:error] = "Forecast error: #{e.message}"
      rescue StandardError => e
        flash[:error] = "An unexpected error occurred: #{e.message}"
      end
    end
  end

  private

  def human_readable_time(time)
    time.strftime("%A, %B %d, %Y %I:%M %p")
  end

  def is_today?(date)
    date.to_date == Date.today
  end
  helper_method :human_readable_time, :is_today?
end
