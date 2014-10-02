module Bplgeo
  require "bplgeo/constants"
  require "bplgeo/parser"
  require "bplgeo/standardizer"
  require "bplgeo/tgn"
  require "bplgeo/geonames"
  require "bplgeo/town_lookup"
  require "geocoder"
  require "countries"
  require "unidecoder"
  require "typhoeus"
  require "nokogiri"
  require "htmlentities"

  def self.parse(term,parse_term=false)
    return {} if term.blank?

    return_hash = Bplgeo::Parser.parse_mapquest_api(term, parse_term)

    if return_hash.blank?
      return_hash = Bplgeo::Parser.parse_bing_api(term, parse_term)
    end

    if return_hash.blank?
      return_hash = Bplgeo::Parser.parse_google_api(term, parse_term)
    end

    if return_hash[:country_part].present?
      #FIXME
      return_hash[:tgn] = Bplgeo::TGN.tgn_id_from_geo_hash(return_hash)

      if return_hash[:tgn].blank?
        geo_hash_temp =  Bplgeo::Standardizer.try_with_entered_names(return_hash)
        return_hash[:tgn] = Bplgeo::TGN.tgn_id_from_geo_hash(geo_hash_temp) if geo_hash_temp.present?

        if return_hash[:tgn].blank? && return_hash[:neighborhood_part].present?

          geo_hash_temp = return_hash.clone
          geo_hash_temp[:neighborhood_part] = nil
          geo_hash_temp[:original_string_differs] = true
          return_hash[:tgn] = Bplgeo::TGN.tgn_id_from_geo_hash(geo_hash_temp)
          return_hash[:tgn][:original_string_differs] = true if return_hash[:tgn].present?
        elsif return_hash[:city_part].present? && return_hash[:tgn].blank?

          geo_hash_temp = return_hash.clone
          geo_hash_temp[:city_part] = nil
          geo_hash_temp[:original_string_differs] = true
          return_hash[:tgn] = Bplgeo::TGN.tgn_id_from_geo_hash(geo_hash_temp)
          return_hash[:tgn][:original_string_differs] = true if return_hash[:tgn].present?

        end

      end

      return_hash[:geonames] = Bplgeo::Geonames.geonames_id_from_geo_hash(return_hash)
    end

    return return_hash

  end
end
