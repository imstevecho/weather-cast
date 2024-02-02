class GeocodeService
  include CacheKeyGenerator
  BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'.freeze
  CACHE_EXPIRATION = 1.month.freeze

  # Fetch coordinates by address
  def coords_by_address(address, skip_cache: false)
    fetch_geo_info('geocode', address, skip_cache: skip_cache)
  rescue StandardError => e
    Rails.logger.error "Error fetching coordinates by address: #{e.message}"
    nil
  end

  # Fetch coordinates by zipcode
  def coords_by_zipcode(zipcode, country_code = 'US', skip_cache: false)
    query = "#{zipcode},#{country_code}"
    fetch_geo_info('geocode', query, skip_cache: skip_cache)
  rescue StandardError => e
    Rails.logger.error "Error fetching coordinates by zipcode: #{e.message}"
    nil
  end

  private

  # General method to fetch geographic information
  def fetch_geo_info(prefix, query, skip_cache: false)
    key = cache_key(prefix, query)
    CachingService.fetch(key, expires_in: CACHE_EXPIRATION, skip_cache: skip_cache) do
      Rails.logger.info "Fetching geocode for #{query}"
      parsed_response = fetch(query)
      extract_location_info(parsed_response)
    end
  rescue StandardError => e
    Rails.logger.error "Error in fetch_geo_info: #{e.message}"
    raise
  end

  # Make API request and parse JSON response
  def fetch(address)
    query = {
      address: address,
      key: ENV['GOOGLE_MAPS_API_KEY']
    }
    response = HTTParty.get(BASE_URL, { query: query })
    raise 'API Error' unless response.success?

    JSON.parse(response.body)
  rescue HTTParty::Error, JSON::ParserError => e
    Rails.logger.error "API request or parsing failed: #{e.message}"
    raise
  end

  # Extract latitude, longitude, and zip code from parsed response
  def extract_location_info(parsed_response)
    lat = parsed_response.dig('results', 0, 'geometry', 'location', 'lat')
    lon = parsed_response.dig('results', 0, 'geometry', 'location', 'lng')
    zip = parsed_response.dig('results', 0, 'address_components').find do |comp|
            comp['types'].include?('postal_code')
          end&.dig('short_name')

    { lat: lat, lon: lon, zip: zip }
  end
end
