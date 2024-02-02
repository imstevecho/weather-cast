class GeocodeService
  include CacheKeyGenerator
  BASE_URL = 'https://maps.googleapis.com/maps/api/geocode/json'

  def address(address, skip_cache: false)
    key = cache_key('geocode', address)
    CachingService.fetch(key, expires_in: 1.month, skip_cache: skip_cache) do
      puts "Fetching geocode for #{address}"
      parsed_response = fetch(address)
      lat = parsed_response.dig('results', 0, 'geometry', 'location', 'lat')
      lon = parsed_response.dig('results', 0, 'geometry', 'location', 'lng')
      { lat: lat, lon: lon }
    end
  end

  private

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
end
