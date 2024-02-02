class ForecastService
  BASE_URL = 'https://api.openweathermap.org/data/2.5'.freeze

  def initialize
    @options = {
      id: ENV['OPENWEATHER_API_ID'],
      appid: ENV['OPENWEATHER_API_KEY'],
      units: ENV['OPENWEATHER_UNITS']
    }
  end

  # Fetch weather forecast data based on latitude and longitude
  def with_lat_lon(lat, lon)
    Rails.logger.info "Fetching forecast for #{lat}, #{lon}"
    parsed_response = fetch('/forecast', { lat: lat, lon: lon })
    parse_forecast(parsed_response['list'])
  rescue StandardError => e
    Rails.logger.error "Failed to fetch forecast: #{e.message}"
    raise
  end

  private

  # Fetch API response and parse it
  def fetch(path, query = {})
    full_query = query.merge(@options)
    url = "#{BASE_URL}#{path}"
    response = HTTParty.get(url, { query: full_query })

    JSON.parse(response.body).tap do |_parsed_response|
      raise 'API Error' unless response.success?
    end
  end

  # Parse the forecast data from API response
  def parse_forecast(list)
    list.map do |forecast|
      {
        date: forecast['dt'],
        temp: forecast['main']['temp'],
        temp_min: forecast['main']['temp_min'],
        temp_max: forecast['main']['temp_max']
      }
    end
  end
end
