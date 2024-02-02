# Handles caching logic for various services
class CachingService
  DEFAULT_EXPIRATION = 1.hour.freeze

  class << self
    # Fetch data from cache or execute block if data is not cached or caching is skipped.
    #
    # @param key [String] Cache key
    # @param expires_in [ActiveSupport::Duration] Cache expiration time
    # @param skip_cache [Boolean] Flag to skip caching
    # @return [Object] Cached or freshly generated data
    def fetch(key, expires_in: DEFAULT_EXPIRATION, skip_cache: false, &block)
      return yield if skip_cache

      Rails.cache.fetch(key, expires_in: expires_in, &block)
    end
  end
end
