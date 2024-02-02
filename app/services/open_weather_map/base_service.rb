module OpenWeatherMap
  class BaseService
    def initialize(base_uri, options = {})
      @base_uri = base_uri
      @options = options.merge({
                                 id: ENV['OPENWEATHER_API_ID'],
                                 appid: ENV['OPENWEATHER_API_KEY'],
                                 units: ENV['OPENWEATHER_UNITS']
                               })
    end

    def fetch(path, query = {})
      full_query = query.merge(@options)
      response = HTTParty.get("#{@base_uri}#{path}", { query: full_query })
      JSON.parse(response.body).tap do |_parsed_response|
        raise 'API Error' unless response.success?
      end
    end
  end
end
