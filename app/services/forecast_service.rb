# frozen_string_literal: true

class ForecastService
  class ForecastError < StandardError; end

  BASE_URL = 'https://api.openweathermap.org/data/2.5'.freeze

  def initialize(country_code = 'US')
    @options = {
      id: ENV.fetch('OPENWEATHER_API_ID', nil),
      appid: ENV.fetch('OPENWEATHER_API_KEY'),
      units: country_code == 'CA' ? 'metric' : 'imperial'
    }
  end

  # Fetch weather forecast data based on latitude and longitude
  def with_lat_lon(lat, lon)
    Rails.logger.info "Fetching forecast for #{lat}, #{lon}"
    parsed_response = fetch('/forecast', { lat: lat, lon: lon })
    parse_forecast(parsed_response['list'])
  rescue StandardError => e
    handle_error("Failed to fetch forecast: #{e.message}")
  end

  private

  # Fetch API response and parse it
  def fetch(path, query = {})
    full_query = query.merge(@options)
    url = "#{BASE_URL}#{path}"
    response = HTTParty.get(url, query: full_query)

    raise ForecastError, 'API request failed' unless response.success?

    JSON.parse(response.body)
  rescue HTTParty::Error, JSON::ParserError => e
    handle_error("API request or parsing failed: #{e.message}")
  end

  # Parse the forecast data from API response
  def parse_forecast(list)
    list.map do |forecast|
      {
        date: Time.at(forecast['dt']).utc,
        temp: forecast.dig('main', 'temp'),
        temp_min: forecast.dig('main', 'temp_min'),
        temp_max: forecast.dig('main', 'temp_max'),
        description: forecast.dig('weather', 0, 'description'),
        icon: forecast.dig('weather', 0, 'icon')
      }
    end
  end

  def handle_error(message)
    Rails.logger.error(message)
    raise ForecastError, message
  end
end
