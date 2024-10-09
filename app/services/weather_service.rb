class WeatherService
  class LocationNotFoundError < StandardError; end
  class ForecastUnavailableError < StandardError; end

  include CacheKeyGenerator

  CACHE_IDENTIFIER = "weather".freeze
  CACHE_EXPIRATION = 30.minutes.freeze
  ZIP_PATTERN = /^\d{5}$/.freeze

  def initialize(geocode_service: GeocodeService.new, forecast_service: nil)
    @geocode_service = geocode_service
    @forecast_service = forecast_service
  end

  def fetch_weather(address_or_zip)
    location_info = fetch_location_info(address_or_zip)
    country_code = location_info[:country_code]
    @forecast_service ||= ForecastService.new(country_code)
    weather_data = fetch_weather_data(location_info)

    {
      is_from_cache: weather_data[:is_from_cache],
      forecast_data: weather_data[:data],
      zip: location_info[:zip],
      country_code: country_code
    }
  end

  private

  def fetch_location_info(address_or_zip)
    result = if looks_like_zip?(address_or_zip)
               @geocode_service.coords_by_zipcode(address_or_zip, 'US')
             else
               @geocode_service.coords_by_address(address_or_zip)
             end

    raise LocationNotFoundError, "Can't find coordinates for #{address_or_zip}" unless result&.dig(:data)

    result[:data]
  rescue StandardError => e
    Rails.logger.error "Error fetching location info: #{e.message}"
    raise LocationNotFoundError, e.message
  end

  def fetch_weather_data(location_info)
    key = cache_key(CACHE_IDENTIFIER, location_info[:zip])

    CachingService.fetch(key, expires_in: CACHE_EXPIRATION) do
      Rails.logger.info "Fetching weather for ZIP #{location_info[:zip]}"
      @forecast_service.with_lat_lon(location_info[:lat], location_info[:lon])
    end
  rescue StandardError => e
    Rails.logger.error "Error fetching weather data: #{e.message}"
    raise ForecastUnavailableError, e.message
  end

  def looks_like_zip?(str)
    ZIP_PATTERN.match?(str.to_s)
  end
end
