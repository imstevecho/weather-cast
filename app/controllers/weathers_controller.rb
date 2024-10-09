class WeathersController < ApplicationController
  before_action :initialize_services

  def index
    @query = params[:q]
    fetch_and_handle_weather if @query.present?
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
  rescue WeatherService::LocationNotFoundError,
         WeatherService::ForecastUnavailableError,
         StandardError => e
    handle_error(e)
  end

  def set_weather_data(result)
    @forecast_data = result[:forecast_data]
    @is_from_cache = result[:is_from_cache]
    @zip = result[:zip]
    @country_code = result[:country_code]
  end

  def handle_error(error)
    log_error(error)
    flash.now[:alert] = error_message_for(error)
    render :index, status: error_status_for(error)
  end

  def error_message_for(error)
    case error
    when WeatherService::LocationNotFoundError
      "We couldn't find that location. Please check your input and try again."
    when WeatherService::ForecastUnavailableError
      "We're sorry, but we can't retrieve the weather information at the moment. Our forecast service might be temporarily unavailable. Please try again later."
    else
      "An unexpected error occurred. Our team has been notified."
    end
  end

  def error_status_for(error)
    error.is_a?(StandardError) ? :internal_server_error : :unprocessable_entity
  end

  def log_error(error)
    Rails.logger.error "Failed to fetch weather: #{error.message}"
  end
end
