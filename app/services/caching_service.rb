class CachingService
  def self.fetch(key, expires_in: 1.hour, skip_cache: false, &block)
    if skip_cache
      yield
    else
      Rails.cache.fetch(key, expires_in: expires_in, &block)
    end
  end
end
