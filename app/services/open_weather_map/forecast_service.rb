module OpenWeatherMap
  class ForecastService < BaseService
    def initialize
      super('https://api.openweathermap.org/data/2.5')
    end

    def with_lat_lon(lat, lon)
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
end
