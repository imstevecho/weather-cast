class ForecastService
  include CacheKeyGenerator
  BASE_URL = 'https://api.openweathermap.org/data/2.5'

  def initialize
    @options = {
      id: ENV['OPENWEATHER_API_ID'],
      appid: ENV['OPENWEATHER_API_KEY'],
      units: ENV['OPENWEATHER_UNITS']
    }
  end

  def with_lat_lon(lat, lon, skip_cache: false)
    key = cache_key('forecast', lat, lon)
    CachingService.fetch(key, expires_in: 10.minutes, skip_cache: skip_cache) do
      puts "fetching forecast for #{lat},#{lon}"
      query = { lat: lat, lon: lon }
      parsed_response = fetch('/forecast', query)

      parsed_response['list'].map do |forecast|
        {
          date: forecast['dt'],
          temp: forecast['main']['temp'],
          temp_min: forecast['main']['temp_min'],
          temp_max: forecast['main']['temp_max']
        }
      end
    end
  end

  private

  def fetch(path, query = {})
    full_query = query.merge(@options)
    url = "#{BASE_URL}#{path}"
    response = HTTParty.get(url, { query: full_query })
    JSON.parse(response.body).tap do |_parsed_response|
      raise 'API Error' unless response.success?
    end
  end
end
