# Handles caching logic for various services
class CachingService
  DEFAULT_EXPIRATION = 1.hour.freeze

  class << self
    def fetch(key, expires_in: DEFAULT_EXPIRATION, skip_cache: false)
      if !skip_cache && Rails.cache.exist?(key)
        cached_value = Rails.cache.read(key)
        {data: cached_value, is_from_cache: true}
      else
        yield_result = yield
        Rails.cache.write(key, yield_result, expires_in: expires_in)
        {data: yield_result, is_from_cache: false}
      end
    end
  end
end
