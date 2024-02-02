# Handles caching logic for various services
class CachingService
  DEFAULT_EXPIRATION = 1.hour.freeze

  class << self
    def fetch(key, expires_in: 1.hour, skip_cache: false)
      if !skip_cache && Rails.cache.exist?(key)
        {data: Rails.cache.read(key), is_from_cache: true}
      else
        yield_result = yield
        Rails.cache.write(key, yield_result, expires_in: expires_in)
        {data: yield_result, is_from_cache: false}
      end
    end
  end
end
