module Geomash
  class Parser

    def self.mapquest_key
      Geomash.config[:mapquest_key] || '<mapquest_key>'
    end

    def self.bing_key
      Geomash.config[:bing_key] || '<bing_key>'
    end

    def self.timeout
      Geomash.config[:timeout]
    end

    #Note: Limited to only looking at United States places...
    def self.parse_bing_api(term, parse_term_flag=false)
      return_hash = {}
      retry_count = 3

      #Skip if no bing_key... possibly move this elsewhere?
      return return_hash if self.bing_key == '<bing_key>'

      return_hash[:original_term] = term

      term = Geomash::Standardizer.parse_for_geographic_term(term) if parse_term_flag
      term = Geomash::Standardizer.standardize_geographic_term(term)

      if term.blank?
        return {}
      end

      return_hash[:standardized_term] = term

      #Bing API does badly with parentheses...
      if term.match(/[\(\)]+/)
        return {}
      end

      #Sometimes with building, city, state, bing is dumb and will only return state. Example: Boston Harbor, Boston, Mass.
      #So if not a street address, pass to have google handle it for better results...
      #Example of another bad record: South Street bridge, West Bridgewater, Mass. would give a place in Holyoke
      if term.split(',').length >= 3 && term.match(/\d/).blank? && term.downcase.match(/ave\.*,/).blank? && term.downcase.match(/avenue\.*,/).blank? && term.downcase.match(/street\.*,/).blank? && term.downcase.match(/st\.*,/).blank? && term.downcase.match(/road\.*,/).blank? && term.downcase.match(/rd\.*,/).blank?
        return {}
      end

      Geocoder.configure(:lookup => :bing,:api_key => self.bing_key,:timeout => self.timeout, :always_raise => :all)
      bing_api_result = Geocoder.search(term)

    rescue SocketError => e
      retry unless (retry_count -= 1).zero?
    else

      #Use only for United States results... international results are inaccurate.
      if bing_api_result.present? && bing_api_result.first.data["address"]["countryRegion"] == 'United States'

        if bing_api_result.first.data["entityType"] == 'Neighborhood'
          return {} #Doesn't return a city... Google handles this better.
        end

        if bing_api_result.first.data["address"]["addressLine"].present?
          return_hash[:term_differs_from_tgn] = true
          return_hash[:street_part] = bing_api_result.first.data["address"]["addressLine"]
          return_hash[:coords] = {:latitude=>bing_api_result.first.data["geocodePoints"].first["coordinates"].first.to_s,
                                       :longitude=>bing_api_result.first.data["geocodePoints"].first["coordinates"].last.to_s,
                                       :combined=>bing_api_result.first.data["geocodePoints"].first["coordinates"].first.to_s + ',' + bing_api_result.first.data["geocodePoints"].first["coordinates"].last.to_s}
        end

        return_hash[:country_part] = bing_api_result.first.data["address"]["countryRegion"]

        if return_hash[:country_part] == 'United States'
          return_hash[:state_part] = Geomash::Constants::STATE_ABBR[bing_api_result.first.data["address"]["adminDistrict"]]
        else
          return_hash[:state_part] = bing_api_result.first.data["address"]["adminDistrict"]
        end

        return_hash[:city_part] = bing_api_result.first.data["address"]["locality"]
      else
        return {}
      end

      #Only return if USA for now. International results often awful.
      return return_hash[:country_part] == 'United States' ? return_hash : {}
    end

    #Mapquest allows unlimited requests - start here?
    def self.parse_mapquest_api(term, parse_term_flag=false)
      return_hash = {}
      retry_count = 3

      #Skip if no bing_key... possibly move this elsewhere?
      return return_hash if self.mapquest_key == '<mapquest_key>'

      return_hash[:original_term] = term

      term = Geomash::Standardizer.parse_for_geographic_term(term) if parse_term_flag
      term = Geomash::Standardizer.standardize_geographic_term(term)

      if term.blank?
        return {}
      end

      return_hash[:standardized_term] = term

      #Mapquest returns bad data for: Manchester, Mass.
      if term.include?('Manchester') || term.include?('Atlanta, MI')
        return {}
      end

      #Messed up with just neighborhoods. Example: Hyde Park (Boston, Mass.) or Hyde Park (Boston, Mass.)
      #So if not a street address, pass to have google handle it for better results...
      if term.split(',').length >= 3 && term.match(/\d/).blank? && term.downcase.match(/ave\.*,/).blank? && term.downcase.match(/avenue\.*,/).blank? && term.downcase.match(/street\.*,/).blank? && term.downcase.match(/st\.*,/).blank? && term.downcase.match(/road\.*,/).blank? && term.downcase.match(/rd\.*,/).blank?
        return {}
      end

      Geocoder.configure(:lookup => :mapquest,:api_key => self.mapquest_key,:timeout => self.timeout, :always_raise => :all)

      mapquest_api_result = Geocoder.search(term)
    rescue SocketError => e
      retry unless (retry_count -= 1).zero?
    else


      #If this call returned a result...
      if mapquest_api_result.present?

        if mapquest_api_result.first.data["street"].present?
          #return_hash[:term_differs_from_tgn] = true
          return_hash[:street_part] = mapquest_api_result.first.data["street"]
          return_hash[:coords] = {:latitude=>mapquest_api_result.first.data['latLng']['lat'].to_s,
                                       :longitude=>mapquest_api_result.first.data['latLng']['lng'].to_s,
                                       :combined=>mapquest_api_result.first.data['latLng']['lat'].to_s + ',' + mapquest_api_result.first.data['latLng']['lng'].to_s}
        end

        return_hash[:country_part] = Country.new(mapquest_api_result.first.data["adminArea1"]).name

        if return_hash[:country_part] == 'United States'
          return_hash[:state_part] = Geomash::Constants::STATE_ABBR[mapquest_api_result.first.data["adminArea3"]] || mapquest_api_result.first.data["adminArea4"]
        else
          return_hash[:state_part] = mapquest_api_result.first.data["adminArea3"].gsub(' province', '')
        end

        return_hash[:city_part] = mapquest_api_result.first.data["adminArea5"]

        return_hash[:city_part] = return_hash[:city_part].gsub(' City', '') #Return New York as New York City...
      end

      #Only return if USA for now. Google is better with stuff like: 'Long Binh, Vietnam'
      #Also only return if there is a city if there were more than two terms passed in. Fixes: Roxbury, MA
      return {} unless return_hash[:country_part] == 'United States'
      return {} if term.split(',').length >= 2 && return_hash[:city_part].blank?

      return return_hash
    end

    #Final fallback is google API. The best but we are limited to 2500 requests per day unless we pay the $10k a year premium account...
    #Note: If google cannot find street, it will return just city/state, like for "Salem Street and Paradise Road, Swampscott, MA, 01907"
    #Seems like it sets a partial_match=>true in the data section...
    def self.parse_google_api(term, parse_term_flag=false)
      return_hash = {}
      retry_count = 3

      return_hash[:original_term] = term

      term = Geomash::Standardizer.parse_for_geographic_term(term) if parse_term_flag
      term = Geomash::Standardizer.standardize_geographic_term(term)

      #Soviet Union returns back a place in Kazakhstan
      if term.blank? || term == 'Soviet Union'
        return {}
      end

      return_hash[:standardized_term] = term

      ::Geocoder.configure(:lookup => :google,:api_key => nil,:timeout => self.timeout, :always_raise => :all)

      google_api_result = ::Geocoder.search(term)
    rescue SocketError => e
      retry unless (retry_count -= 1).zero?
    else


      #Check if only a partial match. To avoid errors, strip out the first part and try again...
      #Need better way to check for street endings. See: http://pe.usps.gov/text/pub28/28apc_002.htm
      if google_api_result.present?
        if google_api_result.first.data['partial_match'] && term.split(',').length > 1 && !term.downcase.include?('street') && !term.downcase.include?('st.') && !term.downcase.include?('avenue') && !term.downcase.include?('ave.') && !term.downcase.include?('court') && !term.downcase.include?('dr.')
          term = term.split(',')[1..term.split(',').length-1].join(',').strip
          google_api_result = Geocoder.search(term)
        end
      end

      if google_api_result.present?
        #Types: street number, route, neighborhood, establishment, transit_station, bus_station
        google_api_result.first.data["address_components"].each do |result|
          if (result['types'] & ['street number', 'route', 'establishment', 'transit_station', 'bus_station']).present? || (result['types'].include?('neighborhood') && !result['types'].include?('political'))
            #return_hash[:term_differs_from_tgn] = true
            #TODO: Not implemented for Google results right now.
            #return_hash[:street_part] = 'TODO: Not Implemented for Google Results'
            return_hash[:coords] = {:latitude=>google_api_result.first.data['geometry']['location']['lat'].to_s,
                                         :longitude=>google_api_result.first.data['geometry']['location']['lng'].to_s,
                                         :combined=>google_api_result.first.data['geometry']['location']['lat'].to_s + ',' + google_api_result.first.data['geometry']['location']['lng'].to_s}
          elsif (result['types'] & ['country']).present?
            return_hash[:country_part] = result['long_name']
          elsif (result['types'] & ['administrative_area_level_1']).present?
            return_hash[:state_part] = result['long_name'].to_ascii.gsub('-city', '')
          elsif (result['types'] & ['locality']).present?
            return_hash[:city_part] = result['long_name']
          elsif (result['types'] & ['sublocality', 'political']).length == 2 || result['types'].include?('neighborhood')
              return_hash[:neighborhood_part] = result['long_name']
          end
        end

        return_hash[:term_differs_from_tgn] ||= google_api_result.first.data['partial_match'] unless google_api_result.first.data['partial_match'].blank?
      end


      return return_hash
    end
  end
end
