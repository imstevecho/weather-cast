module CacheKeyGenerator
  def cache_key(*args)
    args.join('_').gsub(/\s+/, '_').downcase
  end
end
