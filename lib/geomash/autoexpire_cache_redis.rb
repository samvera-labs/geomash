# frozen_string_literal: true
#Taken from: https://github.com/alexreisner/geocoder/blob/master/examples/autoexpire_cache_redis.rb

module Geomash
  class AutoexpireCacheRedis
    def initialize(store, ttl = 86400)
      @store = store
      @ttl = ttl
    end

    def [](url)
      @store.[](url)
    end

    def []=(url, value)
      @store.[]=(url, value)
      @store.expire(url, @ttl)
    end

    def keys
      @store.keys
    end

    def del(url)
      @store.del(url)
    end
  end
end
