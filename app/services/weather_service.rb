class WeatherService
  include CacheKeyGenerator
  CACHE_IDENTIFIER = "weather".freeze
  CACHE_EXPIRATION = 30.minute.freeze
  ZIP_PATTERN = /^\d{5}$/  # Defining the ZIP pattern as a constant

  def initialize(geocode_service: GeocodeService.new, forecast_service: ForecastService.new)
    @geocode_service = geocode_service
    @forecast_service = forecast_service
  end

  # Fetch weather data by either ZIP code or address
  def fetch_weather(address_or_zip)
    location_info = fetch_coords_and_zip(address_or_zip)
    return "Can't find coordinates for #{address_or_zip}" unless location_info

    key = cache_key(CACHE_IDENTIFIER, location_info[:zip])

    weather = CachingService.fetch(key, expires_in: CACHE_EXPIRATION) do
      Rails.logger.info "Fetching weather for ZIP #{location_info[:zip]}"
      @forecast_service.with_lat_lon(location_info[:lat], location_info[:lon])
    end    

    { is_from_cache: weather[:is_from_cache], forecast_data: weather[:data], zip: location_info[:zip] }
  rescue StandardError => e
    Rails.logger.error "Error fetching weather: #{e.message}"
    raise
  end

  private

  # Determine if the input is a ZIP code
  def looks_like_zip?(str)
    ZIP_PATTERN.match?(str.to_s)
  end

  # Fetch coordinates based on whether the input is a ZIP code or address
  def fetch_coords_and_zip(address_or_zip)
    if looks_like_zip?(address_or_zip)
      result = @geocode_service.coords_by_zipcode(address_or_zip, 'US')
    else
      result = @geocode_service.coords_by_address(address_or_zip)
    end

    result[:data]
  end
end
