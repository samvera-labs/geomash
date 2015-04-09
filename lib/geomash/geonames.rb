module Geomash
  class Geonames

    def self.geonames_username
      Geomash.config[:geonames_username] || '<username>'
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
        #FIXME: Will be corrected as part of Geomash rename later this week.
        begin
          coords[:box] = {}
          coords[:box][:west] = geoname.bbox.west.text
          coords[:box][:north] = geoname.bbox.north.text
          coords[:box][:east] = geoname.bbox.east.text
          coords[:box][:south] = geoname.bbox.south.text
        rescue
          coords[:box] = {}
        end

        geonames_data[:coords] = coords
        geonames_data[:hier_geo] = hier_geo.present? ? hier_geo : nil
      end

      return geonames_data
    end


    def self.geonames_id_from_geo_hash(geo_hash)
      return nil if Geomash::Geonames.geonames_username == '<username>'
      geo_hash = geo_hash.clone

      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      geonames_search_array = []
      return_hash = {}

      #Don't do both neighborhood and city!
      if geo_hash[:neighborhood_part].present?
        geonames_search_array << geo_hash[:neighborhood_part]
        exact_name_term = geo_hash[:neighborhood_part]
      elsif geo_hash[:city_part].present?
        geonames_search_array << geo_hash[:city_part]
        exact_name_term = geo_hash[:neighborhood_part]
      end

      geonames_search_array << geo_hash[:state_part] if geo_hash[:state_part].present?
      exact_name_term ||= geo_hash[:neighborhood_part]
      geonames_search_array << geo_hash[:country_part] if geo_hash[:country_part].present?
      exact_name_term ||= geo_hash[:country_part]
      geonames_search_string = geonames_search_array.join(', ')

      exact_name_term =  geonames_search_array.first.strip

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        country_code = nil
        if geo_hash[:country_part] == 'South Korea'
          country_code = 'KR'
        elsif geo_hash[:country_part] == 'North Korea'
          country_code = 'KP'
        else
          country_code = Country.find_country_by_name(geo_hash[:country_part]).alpha2
        end
        geonames_response = Typhoeus::Request.get("http://api.geonames.org/search?username=#{self.geonames_username}&lang=en&style=FULL&q=#{CGI.escape(geonames_search_string)}&name_equals=#{CGI.escape(exact_name_term)}&country=#{country_code}")

      end until (geonames_response.code != 500 || retry_count == max_retry)

      unless geonames_response.code == 500

        parsed_xml = Nokogiri::XML(geonames_response.body)

        raise "geonames status error message of: #{parsed_xml.to_s}" if parsed_xml.xpath("//status").present?

        #This is ugly and needs to be redone to achieve better recursive...
        current_count = parsed_xml.xpath("//totalResultsCount")
        if current_count.blank? || current_count.first.text == '0'
          if geo_hash[:neighborhood_part].present?
            geo_hash_temp = geo_hash.clone
            geo_hash_temp[:neighborhood_part] = nil
            return_hash = geonames_id_from_geo_hash(geo_hash_temp)
            return return_hash if return_hash.present?
          elsif geo_hash[:city_part].present?
            geo_hash_temp = geo_hash.clone
            geo_hash_temp[:city_part] = nil
            return_hash = geonames_id_from_geo_hash(geo_hash_temp)
            return return_hash if return_hash.present?
          end

          return nil
        end

        #Exact Match ... FIXME to not use Slop
        if parsed_xml.xpath("//geonames/geoname/geonameId").present?
          return_hash[:id] = parsed_xml.xpath("//geonames/geoname/geonameId").first.text
          return_hash[:rdf] = "http://sws.geonames.org/#{return_hash[:id]}/about.rdf"
          return_hash[:original_string_differs] = Geomash::Standardizer.parsed_and_original_check(geo_hash)
          return return_hash
        else
          return nil
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
