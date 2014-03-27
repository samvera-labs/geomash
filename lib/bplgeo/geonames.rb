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

    def self.get_geonames_data(geoname_id)
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

        geonames_response = Typhoeus::Request.get("http://api.geonames.org/hierarchy?username=#{self.geonames_username}&lang=en&style=FULL&geonameId=" + geoname_id)

      end until (geonames_response.code != 500 || retry_count == max_retry)

      unless geonames_response.code == 500
        parsed_xml = Nokogiri::Slop(geonames_response.body)

        parsed_xml.geonames.geoname.each do |geoname|
           hier_geo[geoname.fcode.text.downcase.to_sym] = geoname.toponymName.text
        end

        #FIXME: Code4Lib lazy implementation... will get last result
        geoname = parsed_xml.geonames.geoname.last
        coords[:latitude] = geoname.lat.text
        coords[:longitude] = geoname.lng.text
        coords[:combined] = coords[:latitude] + ',' + coords[:longitude]
          coords[:box] = {}
          coords[:box][:west] = geoname.bbox.west.text
          coords[:box][:north] = geoname.bbox.north.text
          coords[:box][:east] = geoname.bbox.east.text
          coords[:box][:south] = geoname.bbox.south.text

        geonames_data[:coords] = coords
        geonames_data[:hier_geo] = hier_geo.present? ? hier_geo : nil
      end

      return geonames_data
    end


    def self.geonames_id_from_geo_hash(geo_hash)
      return nil if Bplgeo::Geonames.geonames_username == '<username>'
      geo_hash = geo_hash.clone

      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      geonames_search_array = []
      return_hash = {}

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

        geonames_response = Typhoeus::Request.get("http://api.geonames.org/search?username=#{self.geonames_username}&lang=en&style=FULL&q=" + CGI.escape(geonames_search_string))

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

        #Exact Match
        parsed_xml.geonames.geoname.each do |geoname|

          current_term = geoname.toponymName.text.to_ascii.downcase.strip

          if current_term == match_term  && return_hash.blank?
            return_hash[:id] = geoname.geonameId.text
            return_hash[:original_string_differs] = Bplgeo::Standardizer.parsed_and_original_check(geo_hash)
            break
          end
        end

        if return_hash.blank?
          #Starts With
          parsed_xml.geonames.geoname.each do |geoname|

            current_term = geoname.toponymName.text.to_ascii.downcase.strip

            if current_term.starts_with?(match_term) && return_hash.blank?
              return_hash[:id] = geoname.geonameId.text
              return_hash[:original_string_differs] = Bplgeo::Standardizer.parsed_and_original_check(geo_hash)
            end
          end
        end

      end

      if geonames_response.code == 500
        raise 'Geonames Server appears to not be responding for Geographic query: ' + term
      end

      return return_hash if return_hash.present?

      return nil

      end
  end
end