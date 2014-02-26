module Bplgeo
  class TGN

    def self.bplgeo_config
      root = Rails.root || './test/dummy'
      env = Rails.env || 'test'
      @bplgeo_config ||= YAML::load(ERB.new(IO.read(File.join(root, 'config', 'bplgeo.yml'))).result)[env].with_indifferent_access
    end

    def self.getty_username
      bplgeo_config[:getty_username]
    end

    def self.getty_password
      bplgeo_config[:getty_password]
    end

    # retrieve data from Getty TGN to populate <mods:subject auth="tgn">
    def self.get_tgn_data(tgn_id)
      tgn_response = Typhoeus::Request.get('http://vocabsservices.getty.edu/TGNService.asmx/TGNGetSubject?subjectID=' + tgn_id, userpwd: self.getty_username + ':' + self.getty_password)
      unless tgn_response.code == 500
        tgnrec = Nokogiri::XML(tgn_response.body)
        #puts tgnrec.to_s

        # coordinates
        if tgnrec.at_xpath("//Coordinates")
          coords = {}
          coords[:latitude] = tgnrec.at_xpath("//Latitude/Decimal").children.to_s
          coords[:longitude] = tgnrec.at_xpath("//Longitude/Decimal").children.to_s
        else
          coords = nil
        end

        hier_geo = {}

        #main term
        if tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text")
          tgn_term_type = tgnrec.at_xpath("//Preferred_Place_Type/Place_Type_ID").children.to_s
          pref_term_langs = tgnrec.xpath("//Terms/Preferred_Term/Term_Languages/Term_Language/Language")
          # if the preferred term is the preferred English form, use that
          if pref_term_langs.children.to_s.include? "English"
            tgn_term = tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text").children.to_s
          else # use the non-preferred term which is the preferred English form
            if tgnrec.xpath("//Terms/Non-Preferred_Term")
              non_pref_terms = tgnrec.xpath("//Terms/Non-Preferred_Term")
              non_pref_terms.each do |non_pref_term|
                non_pref_term_langs = non_pref_term.children.css("Term_Language")
                # have to loop through these, as sometimes languages share form
                non_pref_term_langs.each do |non_pref_term_lang|
                  if non_pref_term_lang.children.css("Preferred").children.to_s == "Preferred" && non_pref_term_lang.children.css("Language").children.to_s == "English"
                    tgn_term = non_pref_term.children.css("Term_Text").children.to_s
                  end
                end
              end
            end
          end
          # if no term is the preferred English form, just use the preferred term
          tgn_term ||= tgnrec.at_xpath("//Terms/Preferred_Term/Term_Text").children.to_s
        end
        if tgn_term && tgn_term_type
          case tgn_term_type
            when '29000/continent'
              hier_geo[:continent] = tgn_term
            when '81010/nation'
              hier_geo[:country] = tgn_term
            when '81161/province'
              hier_geo[:province] = tgn_term
            when '81165/region', '82193/union', '80005/semi-independent political entity'
              hier_geo[:region] = tgn_term
            when '81175/state', '81117/department', '82133/governorate'
              hier_geo[:state] = tgn_term
            when '81125/national district'
              if tgn_term == 'District of Columbia'
                hier_geo[:state] = tgn_term
              else
                hier_geo[:territory] = tgn_term
              end
            when '81181/territory', '81021/dependent state', '81186/union territory'
              hier_geo[:territory] = tgn_term
            when '81115/county'
              hier_geo[:county] = tgn_term
            when '83002/inhabited place'
              hier_geo[:city] = tgn_term
            when '84251/neighborhood'
              hier_geo[:city_section] = tgn_term
            when '21471/island'
              hier_geo[:island] = tgn_term
            when '81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division'
              hier_geo[:area] = tgn_term
            else
              non_hier_geo = tgn_term
          end
        end

        # parent data for <mods:hierarchicalGeographic>
        if tgnrec.at_xpath("//Parent_String")
          parents = tgnrec.at_xpath("//Parent_String").children.to_s.split('], ')
          parents.each do |parent|
            if parent.include? '(continent)'
              hier_geo[:continent] = parent
            elsif parent.include? '(nation)'
              hier_geo[:country] = parent
            elsif parent.include? '(province)'
              hier_geo[:province] = parent
            elsif (parent.include? '(region)') || (parent.include? '(union)') || (parent.include? '(semi-independent political entity)')
              hier_geo[:region] = parent
            elsif (parent.include? '(state)') || (parent.include? '(department)') || (parent.include? '(governorate)') || (parent.include?('(national district)') && parent.include?('District of Columbia'))
              hier_geo[:state] = parent
            elsif (parent.include? '(territory)') || (parent.include? '(dependent state)') || (parent.include? '(union territory)') || (parent.include? '(national district)')
              hier_geo[:territory] = parent
            elsif parent.include? '(county)'
              hier_geo[:county] = parent
            elsif parent.include? '(inhabited place)'
              hier_geo[:city] = parent
            elsif parent.include? '(neighborhood)'
              hier_geo[:city_section] = parent
            elsif parent.include? '(island)'
              hier_geo[:island] = parent
            elsif (parent.include? '(area)') || (parent.include? '(general region)') || (parent.include? '(deserted settlement)') || (parent.include? '(historical region)') || (parent.include? '(national division)')
              hier_geo[:area] = parent
            end
          end
          hier_geo.each do |k,v|
            hier_geo[k] = v.gsub(/ \(.*/,'')
          end
        end

        tgn_data = {}
        tgn_data[:coords] = coords
        tgn_data[:hier_geo] = hier_geo.length > 0 ? hier_geo : nil
        tgn_data[:non_hier_geo] = non_hier_geo ? non_hier_geo : nil

      else

        tgn_data = nil

      end

      return tgn_data

    end

    def self.tgn_id_from_geo_hash(geo_hash)
      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      geo_hash = Bplgeo::Standardizer.parsed_and_original_check(geo_hash)

      state_part = geo_hash[:state_part]

      country_code = Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_id] unless Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_code ||= ''


      country_part = Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_country_name] unless Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_part ||= geo_hash[:country_part]
      country_part ||= ''

      city_part = geo_hash[:city_part]

      neighborhood_part = geo_hash[:neighborhood_part]

      top_match_term = ''
      match_term = nil

      if city_part.blank? && state_part.blank?
        # Limit to nations
        place_type = 81010
        top_match_term = ['']
        second_top_match_term = ''
        match_term = country_part.to_ascii.downcase
      elsif state_part.present? && city_part.blank? && country_code == 7012149
        #Limit to states
        place_type = 81175
        top_match_term = ["#{country_part.to_ascii.downcase} (nation)"]
        second_top_match_term = ["#{country_part.to_ascii.downcase} (nation)"]
        match_term = state_part.to_ascii.downcase
      elsif state_part.present? && city_part.blank?
        #Limit to regions
        place_type = 81165
        top_match_term = ["#{country_part.to_ascii.downcase} (nation)"]
        second_top_match_term = ["#{country_part.to_ascii.downcase} (nation)"]
        match_term = state_part.to_ascii.downcase
      elsif state_part.present? && city_part.present? && neighborhood_part.blank?
        #Limited to only inhabited places at the moment...
        place_type = 83002
        sp = state_part.to_ascii.downcase
        top_match_term = ["#{sp} (state)", "#{sp} (department)", "#{sp} (governorate)", "#{sp} (territory)", "#{sp} (dependent state)", "#{sp} (union territory)", "#{sp} (national district)",  "#{sp} (province)"]
        second_top_match_term = ["#{country_part.to_ascii.downcase} (nation)"]
        match_term = city_part.to_ascii.downcase
      elsif state_part.present? && city_part.present? && neighborhood_part.present?
        #Limited to only to neighborhoods currently...
        place_type = 84251
        top_match_term = ["#{city_part.to_ascii.downcase} (inhabited place)"]
        sp = neighborhood_part.to_ascii.downcase
        second_top_match_term = ["#{sp} (state)", "#{sp} (department)", "#{sp} (governorate)", "#{sp} (territory)", "#{sp} (dependent state)", "#{sp} (union territory)", "#{sp} (national district)",  "#{sp} (province)"]
        match_term = neighborhood_part.to_ascii.downcase
      else
        return geo_hash
      end

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        tgn_response = Typhoeus::Request.get("http://vocabsservices.getty.edu/TGNService.asmx/TGNGetTermMatch?placetypeid=#{place_type}&nationid=#{country_code}&name=" + CGI.escape(match_term), userpwd: self.getty_username + ':' + self.getty_password)


      end until (tgn_response.code != 500 || retry_count == max_retry)

      unless tgn_response.code == 500
        parsed_xml = Nokogiri::Slop(tgn_response.body)

        #This is ugly and needs to be redone to achieve better recursive...
        if parsed_xml.Vocabulary.Count.text == '0'
          if neighborhood_part.present?
            geo_hash[:neighborhood_part] = nil
            geo_hash = tgn_id_from_geo_hash(geo_hash)
          elsif city_part.present?
            geo_hash[:city_part] = nil
            geo_hash = tgn_id_from_geo_hash(geo_hash)
          end

          return geo_hash
        end

        #Debugging an error
        begin
          parsed_xml.Vocabulary.Subject.first.blank?
        rescue
          puts parsed_xml.to_s
        end

        #If only one result, then not array. Otherwise array....
        if parsed_xml.Vocabulary.Subject.first.blank?
          subject = parsed_xml.Vocabulary.Subject

          current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
          alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

          #FIXME: Term should check for the correct level... temporary fix...
          if current_term == match_term && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            geo_hash[:tgn_id] = subject.Subject_ID.text
          #Check alternative term ids
          elsif alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            geo_hash[:tgn_id] = subject.Subject_ID.text
          elsif current_term == match_term && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            geo_hash[:tgn_id] = subject.Subject_ID.text
          elsif alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            geo_hash[:tgn_id] = subject.Subject_ID.text
          end
        else
          parsed_xml.Vocabulary.Subject.each do |subject|

            current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
            alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

            if current_term == match_term && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
              geo_hash[:tgn_id] = subject.Subject_ID.text
            end
          end

          if geo_hash[:tgn_id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                geo_hash[:tgn_id] = subject.Subject_ID.text
              end
            end
          end

          if geo_hash[:tgn_id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if current_term == match_term && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                geo_hash[:tgn_id] = subject.Subject_ID.text
              end
            end
          end

          if geo_hash[:tgn_id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                geo_hash[:tgn_id] = subject.Subject_ID.text
              end
            end
          end
        end

      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + term
      end


      return geo_hash
    end

    #Only returns one result for now...
    #Need to avoid cases like "Boston" and "East Boston"
    def self.state_town_lookup(state_key, string)
      return_tgn_id = nil
      matched_terms_count = 0
      matching_towns = Bplgeo::Constants::STATE_TOWN_TGN_IDS[state_key.to_sym].select {|hash| string.include?(hash[:location_name])}
      matching_towns.each do |matching_town|
        if matching_town[:location_name].split(' ').length > matched_terms_count
          return_tgn_id = matching_town[:tgn_id]
          matched_terms_count = matched_terms_count
        end
      end

      return return_tgn_id
    end
  end
end