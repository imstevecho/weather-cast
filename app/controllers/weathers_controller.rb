class WeathersController < ApplicationController
  before_action :initialize_services

  def index
    @query = params[:q]
    return if @query.blank?

    fetch_and_handle_weather
  end

  private

  def initialize_services
    @weather_service = WeatherService.new(
      geocode_service: GeocodeService.new,
      forecast_service: ForecastService.new
    )
  end

  def fetch_and_handle_weather
    result = @weather_service.fetch_weather(@query)
    set_weather_data(result)
  rescue WeatherService::LocationNotFoundError => e
    handle_location_not_found(e)
  rescue WeatherService::ForecastUnavailableError => e
    handle_forecast_unavailable(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  def set_weather_data(result)
    @forecast_data = result[:forecast_data]
    @is_from_cache = result[:is_from_cache]
    @zip = result[:zip]
  end

  def handle_location_not_found(error)
    log_error(error)
    flash.now[:alert] = "We couldn't find that location. Please check your input and try again."
    render :index
  end

  def handle_forecast_unavailable(error)
    log_error(error)
    flash.now[:alert] = "We're sorry, but we can't retrieve the weather information at the moment. Our forecast service might be temporarily unavailable. Please try again later."
    render :index
  end

  def handle_unexpected_error(error)
    log_error(error)
    flash.now[:error] = "An unexpected error occurred. Our team has been notified."
    render :index, status: :internal_server_error
  end

  def log_error(error)
    Rails.logger.error "Failed to fetch weather: #{error.message}"
  end
end
