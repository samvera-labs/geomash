# frozen_string_literal: true

module Geomash
  require 'geocoder'
  require 'countries'
  require 'stringex'
  require 'typhoeus'
  require 'nokogiri'
  require 'htmlentities'
  require 'active_support'
  require 'active_support/core_ext/string/filters'
  require 'active_support/core_ext/enumerable'
  require 'active_support/core_ext/hash'
  require 'geomash/constants'
  require 'geomash/parser'
  require 'geomash/standardizer'
  require 'geomash/tgn'
  require 'geomash/geonames'
  require 'geomash/town_lookup'
  require 'geomash/autoexpire_cache_dalli'
  require 'geomash/autoexpire_cache_redis'

  def self.config
    @config ||= YAML::load(File.open(config_path))[env]
      .with_indifferent_access
  end

  def self.app_root
    return @app_root if defined?(@app_root)

    @app_root = Rails.root if defined?(Rails) and defined?(Rails.root)
    @app_root ||= APP_ROOT if defined?(APP_ROOT)
    @app_root ||= '.'
  end

  def self.env
    return @env if defined?(@env)
    #The following commented line always returns "test" in a rails c production console. Unsure of how to fix this yet...
    #@env = ENV["RAILS_ENV"] = "test" if ENV
    @env ||= Rails.env if defined?(Rails) and defined?(Rails.root)
    @env ||= 'development'
  end

  def self.config_path
    File.join(app_root, 'config', 'geomash.yml')
  end

  def self.parse(term, parse_term = false)
    return {} if term.blank?

    return_hash = Geomash::Parser.parse_mapquest_api(term, parse_term)

    return_hash = Geomash::Parser.parse_bing_api(term, parse_term) if return_hash.blank?

    return_hash = Geomash::Parser.parse_google_api(term, parse_term) if return_hash.blank?

    if return_hash[:country_part].present?
      #FIXME
      return_hash[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(return_hash)

      if return_hash[:tgn].blank? || (return_hash[:tgn][:original_string_differs] && return_hash[:state_part].present?)
        geo_hash_temp =  Geomash::Standardizer.try_with_entered_names(return_hash)
        geo_hash_temp[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(geo_hash_temp)  if geo_hash_temp.present?
        if geo_hash_temp.present? && return_hash[:tgn].blank?
          return_hash[:tgn] = geo_hash_temp[:tgn]
        elsif geo_hash_temp.present? && geo_hash_temp[:tgn][:parse_depth] > return_hash[:tgn][:parse_depth]
          return_hash[:tgn] = geo_hash_temp[:tgn]
        end
      end

      return_hash[:geonames] = Geomash::Geonames.geonames_id_from_geo_hash(return_hash)
    end
    return_hash
  end
end
