class WeathersController < ApplicationController
  before_action :initialize_services

  def index
    query = params[:q]
    return unless query.present?

    result = @weather_service.fetch_weather(query)
    handle_weather_result(result)
  rescue StandardError => e
    Rails.logger.error "Failed to fetch weather: #{e.message}"
    flash[:error] =
      "We're sorry, but we can't retrieve the weather information at the moment. Our forecast service might be temporarily unavailable. Please try again later."
    redirect_to root_path
  end

  private

  def initialize_services
    geocode_service = GeocodeService.new
    forecast_service = ForecastService.new
    @weather_service = WeatherService.new(
      geocode_service: geocode_service,
      forecast_service: forecast_service
    )
  end

  def handle_weather_result(result)
    unless result
      raise StandardError.new('Could not fetch weather data.')
    end

    @forecast_data = result[:forecast_data]
    @is_from_cache = result[:is_from_cache]
    @zip = result[:zip]
  end
end
