module Bplgeo
  require "bplgeo/constants"
  require "bplgeo/parser"
  require "bplgeo/standardizer"
  require "bplgeo/tgn"
  require "geocoder"
  require "countries"
  require "unidecoder"
  require "typhoeus"
  require "nokogiri"

  def self.parse(term,parse_term=false)
    return {} if term.blank?

    return_hash = Bplgeo::Parser.parse_mapquest_api(term, parse_term)

    if return_hash.blank?
      return_hash = Bplgeo::Parser.parse_bing_api(term, parse_term)
    end

    if return_hash.blank?
      return_hash = Bplgeo::Parser.parse_google_api(term, parse_term)
    end

    return_hash = return_hash.present? ? Bplgeo::TGN.tgn_id_from_geo_hash(return_hash) : {}

    return return_hash

  end
end
