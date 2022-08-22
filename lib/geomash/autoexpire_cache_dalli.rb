# frozen_string_literal: true

# Taken from: https://github.com/alexreisner/geocoder/blob/master/examples/autoexpire_cache_dalli.rb
module Geomash
  class AutoexpireCacheDalli
    def initialize(store, ttl = 86400)
      @store = store
      @keys = 'GeocoderDalliClientKeys'
      @ttl = ttl
    end

    def [](url)
      res = @store.get(url)
      res = YAML::load(res) if res.present?
      res
    end

    def []=(url, value)
      if value.nil?
        del(url)
      else
        key_cache_add(url) if @store.add(url, YAML::dump(value), @ttl)
      end
      value
    end

    def keys
      key_cache
    end

    def del(url)
      key_cache_delete(url) if @store.delete(url)
    end

    private

    def key_cache
      the_keys = @store.get(@keys)
      if the_keys.nil?
        @store.add(@keys, YAML::dump([]))
        []
      else
        YAML::load(the_keys)
      end
    end

    def key_cache_add(key)
      @store.replace(@keys, YAML::dump(key_cache << key))
    end

    def key_cache_delete(key)
      tmp = key_cache
      tmp.delete(key)
      @store.replace(@keys, YAML::dump(tmp))
    end
  end
end
