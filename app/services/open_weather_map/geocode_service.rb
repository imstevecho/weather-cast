module OpenWeatherMap
  class GeocodeService < BaseService
    def initialize
      super('https://api.openweathermap.org/geo/1.0')
    end

    def fetch_by_zip(zip_code, country_code = 'US')
      query = { zip: "#{zip_code},#{country_code}" }
      parsed_response = fetch('/zip', query)

      { lat: parsed_response['lat'], lon: parsed_response['lon'] }
    end
  end
end
