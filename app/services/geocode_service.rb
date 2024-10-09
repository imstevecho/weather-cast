# frozen_string_literal: true

require Rails.root.join('app', 'models', 'concerns', 'retryable')

class GeocodeService
  class GeocodingError < StandardError; end

  include CacheKeyGenerator
  include Retryable

  BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'
  CACHE_EXPIRATION = 1.month
  MAX_RETRIES = 3

  def coords_by_address(address, skip_cache: false)
    fetch_geo_info('address', address, skip_cache: skip_cache)
  end

  def coords_by_zipcode(zipcode, country_code = 'US', skip_cache: false)
    query = "#{zipcode},#{country_code}"
    fetch_geo_info('zipcode', zipcode, query, skip_cache: skip_cache)
  end

  private

  def fetch_geo_info(prefix, key, query, skip_cache: false)
    cache_key = cache_key(prefix, key)
    CachingService.fetch(cache_key, expires_in: CACHE_EXPIRATION, skip_cache: skip_cache) do
      Rails.logger.info "Fetching geocode for #{query}"
      with_retries(max_retries: MAX_RETRIES) { geocode(query) }
    end
  rescue StandardError => e
    handle_error("Error in fetch_geo_info: #{e.message}")
  end

  def geocode(query)
    parsed_response = fetch_from_api(query)
    extract_location_info(parsed_response)
  end

  def fetch_from_api(address)
    response = HTTParty.get(BASE_URL, query: api_query(address))
    raise GeocodingError, 'API request failed' unless response.success?

    JSON.parse(response.body)
  rescue HTTParty::Error, JSON::ParserError => e
    handle_error("API request or parsing failed: #{e.message}")
  end

  def api_query(address)
    {
      address: address,
      key: ENV.fetch('GOOGLE_MAPS_API_KEY')
    }
  end

  def extract_location_info(parsed_response)
    result = parsed_response['results'].first
    raise GeocodingError, 'No results found' if result.nil?

    address_components = result['address_components']
    country_code = find_country_code(address_components)

    Rails.logger.debug "Address components: #{address_components.inspect}"
    Rails.logger.debug "Country code: #{country_code}"

    {
      lat: result.dig('geometry', 'location', 'lat'),
      lon: result.dig('geometry', 'location', 'lng'),
      zip: find_zip_code(address_components),
      country_code: country_code
    }
  end

  def find_zip_code(address_components)
    zip_component = address_components.find { |comp| comp['types'].include?('postal_code') }
    zip_component&.dig('short_name')
  end

  def find_country_code(address_components)
    country_component = address_components.find { |comp| comp['types'].include?('country') }
    Rails.logger.debug "Country component: #{country_component.inspect}"
    country_component&.dig('short_name')
  end

  def handle_error(message)
    Rails.logger.error(message)
    raise GeocodingError, message
  end
end
