class GeocodeService
  include CacheKeyGenerator
  BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  def address(address, skip_cache: false)
    fetch_geo_info('geocode', address, skip_cache: skip_cache)
  end

  def zipcode(zipcode, country_code = 'US', skip_cache: false)
    query = "#{zipcode},#{country_code}"
    fetch_geo_info('geocode', query, skip_cache: skip_cache)
  end

  private

  def fetch_geo_info(prefix, query, skip_cache: false)
    key = cache_key(prefix, query)
    CachingService.fetch(key, expires_in: 1.month, skip_cache: skip_cache) do
      puts "Fetching geocode for #{query}"
      parsed_response = fetch(query)
      extract_lat_lon(parsed_response)
    end
  end

  def fetch(address)
    query = {
      address: address,
      key: ENV['GOOGLE_MAPS_API_KEY']
    }
    response = HTTParty.get(BASE_URL, { query: query })
    JSON.parse(response.body).tap do |_parsed_response|
      raise 'API Error' unless response.success?
    end
  end

  def extract_lat_lon(parsed_response)
    lat = parsed_response.dig('results', 0, 'geometry', 'location', 'lat')
    lon = parsed_response.dig('results', 0, 'geometry', 'location', 'lng')
    { lat: lat, lon: lon }
  end
end
