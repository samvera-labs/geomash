module Bplgeo
  class Geonames
    def self.bplgeo_config
      root = Rails.root || './test/dummy'
      env = Rails.env || 'test'
      @bplgeo_config ||= YAML::load(ERB.new(IO.read(File.join(root, 'config', 'bplgeo.yml'))).result)[env].with_indifferent_access
    end

    def self.geonames_username
      bplgeo_config[:geonames_username] || '<username>'
    end

    def self.get_geoname_data(geoname_id)
      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      hier_geo = {}
      coords = {}
      geonames_data = {}

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        geonames_response = Typhoeus::Request.get("http://api.geonames.org/hierarchy?username=#{self.geonames_username}&lang=en&geonameId=" + geoname_id)

      end until (geonames_response.code != 500 || retry_count == max_retry)

      unless geonames_response.code == 500
        parsed_xml = Nokogiri::Slop(geonames_response.body)

        parsed_xml.geonames.geoname.each do |geoname|
           hier_geo[geoname.fcode.text.downcase.to_sym] = geoname.toponymName.text

          #FIXME: Code4Lib lazy implementation
           coords[:latitude] = geoname.lat.text
           coords[:longitude] = geoname.lng.text
        end

        geonames_data[:coords] = coords
        geonames_data[:hier_geo] = hier_geo.present? ? hier_geo : nil
      end

      return geonames_data
    end


    def self.geonames_id_from_geo_hash(geo_hash)
      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      geo_hash = Bplgeo::Standardizer.parsed_and_original_check(geo_hash)

      geonames_search_array = []

      #Don't do both neighborhood and city!
      if geo_hash[:neighborhood_part].present?
        geonames_search_array << geo_hash[:neighborhood_part]
      elsif geo_hash[:city_part].present?
        geonames_search_array << geo_hash[:city_part]
      end

      geonames_search_array << geo_hash[:state_part] if geo_hash[:state_part].present?
      geonames_search_array << geo_hash[:country_part] if geo_hash[:country_part].present?
      geonames_search_string = geonames_search_array.join(', ')

      match_term =  geonames_search_array.first.to_ascii.downcase.strip

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        geonames_response = Typhoeus::Request.get("http://api.geonames.org/search?username=#{self.geonames_username}&lang=en&q=" + CGI.escape(geonames_search_string))

      end until (geonames_response.code != 500 || retry_count == max_retry)

      unless geonames_response.code == 500

        parsed_xml = Nokogiri::Slop(geonames_response.body)

        #This is ugly and needs to be redone to achieve better recursive...
        if parsed_xml.geonames.totalResultsCount.text == '0'
          if neighborhood_part.present?
            geo_hash[:neighborhood_part] = nil
            geo_hash = geonames_id_from_geo_hash(geo_hash)
          elsif city_part.present?
            geo_hash[:city_part] = nil
            geo_hash = geonames_id_from_geo_hash(geo_hash)
          end

          return geo_hash
        end

        parsed_xml.geonames.geoname.each do |geoname|

          current_term = geoname.toponymName.text.to_ascii.downcase.strip

          if current_term == match_term
            geo_hash[:geonames_id] = geoname.geonameId.text
          end
        end
      end

      if geonames_response.code == 500
        raise 'Geonames Server appears to not be responding for Geographic query: ' + term
      end


      return geo_hash


      end
  end
end