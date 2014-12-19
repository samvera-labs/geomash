module Geomash
  require "geomash/constants"
  require "geomash/parser"
  require "geomash/standardizer"
  require "geomash/tgn"
  require "geomash/geonames"
  require "geomash/town_lookup"
  require "geocoder"
  require "countries"
  require "unidecoder"
  require "typhoeus"
  require "nokogiri"
  require "htmlentities"

  def self.config
    @config ||= begin
                  root = Rails.root || './test/dummy'
                  env = Rails.env || 'test'
                  YAML::load(ERB.new(IO.read(File.join(root, 'config', 'geomash.yml'))).result)[env].with_indifferent_access
                end
  end

  def self.parse(term,parse_term=false)
    return {} if term.blank?

    return_hash = Geomash::Parser.parse_mapquest_api(term, parse_term)

    if return_hash.blank?
      return_hash = Geomash::Parser.parse_bing_api(term, parse_term)
    end

    if return_hash.blank?
      return_hash = Geomash::Parser.parse_google_api(term, parse_term)
    end

    if return_hash[:country_part].present?
      #FIXME
      return_hash[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(return_hash)

      if return_hash[:tgn].blank?
        geo_hash_temp =  Geomash::Standardizer.try_with_entered_names(return_hash)
        return_hash[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(geo_hash_temp) if geo_hash_temp.present?

        if return_hash[:tgn].blank? && return_hash[:neighborhood_part].present?

          geo_hash_temp = return_hash.clone
          geo_hash_temp[:neighborhood_part] = nil
          geo_hash_temp[:original_string_differs] = true
          return_hash[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(geo_hash_temp)
          return_hash[:tgn][:original_string_differs] = true if return_hash[:tgn].present?
        elsif return_hash[:city_part].present? && return_hash[:tgn].blank?

          geo_hash_temp = return_hash.clone
          geo_hash_temp[:city_part] = nil
          geo_hash_temp[:original_string_differs] = true
          return_hash[:tgn] = Geomash::TGN.tgn_id_from_geo_hash(geo_hash_temp)
          return_hash[:tgn][:original_string_differs] = true if return_hash[:tgn].present?

        end

      end

      return_hash[:geonames] = Geomash::Geonames.geonames_id_from_geo_hash(return_hash)
    end

    return return_hash

  end
end
