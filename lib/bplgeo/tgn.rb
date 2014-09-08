module Bplgeo
  class TGN

    def self.bplgeo_config
      root = Rails.root || './test/dummy'
      env = Rails.env || 'test'
      @bplgeo_config ||= YAML::load(ERB.new(IO.read(File.join(root, 'config', 'bplgeo.yml'))).result)[env].with_indifferent_access
    end

    def self.getty_username
      bplgeo_config[:getty_username] || '<username>'
    end

    def self.getty_password
      bplgeo_config[:getty_password] || '<password>'
    end

=begin
      81010/nation
      81175/state
      81165/region
      84251/neighborhood
      83002/inhabited place

      nations
      <http://vocab.getty.edu/tgn/7012149> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207>

      States (political divisions):
          <http://vocab.getty.edu/tgn/7007517> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776> .

      Counties: (Suffolk - http://vocab.getty.edu/aat/300000771)
      <http://vocab.getty.edu/tgn/1002923> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000771> .

      Neighborhood: (Boston)
      <http://vocab.getty.edu/tgn/7013445> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .


      Provinces:
          http://vocab.getty.edu/aat/300000774

      Departments:
          http://vocab.getty.edu/aat/300000772

      Governates:
          http://vocab.getty.edu/aat/300235093

      Territories:
          http://vocab.getty.edu/aat/300135982

      + http://vocab.getty.edu/resource/getty/search?q=territory&luceneIndex=Brief&indexDataset=AAT&_form=%2Fresource%2Fgetty%2Fsearch

      dependent state:
                    http://vocab.getty.edu/aat/300387176


      union territory:
                http://vocab.getty.edu/aat/300387122

      national district:
                   http://vocab.getty.edu/aat/300387081


Roxbury:
http://vocab.getty.edu/tgn/7015002.json



#South Carolina - http://vocab.getty.edu/tgn/7007712

SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> 7007712 .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country ?aat_place_id
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_place_id .
       ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> ?country_label .
    }
    GROUP BY ?parent_country
  }
}
GROUP BY ?object_identifier


=end



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
          coords[:combined] = coords[:latitude] + ',' + coords[:longitude]
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
      return nil if Bplgeo::TGN.getty_username == '<username>'

      geo_hash = geo_hash.clone

      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      return_hash = {}

      state_part = geo_hash[:state_part]

      country_code = Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_id] unless Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_code ||= ''


      country_part = Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_country_name] unless Bplgeo::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_part ||= geo_hash[:country_part]
      country_part ||= ''

      city_part = geo_hash[:city_part]

      neighborhood_part = geo_hash[:neighborhood_part]



      if city_part.blank? && state_part.blank?
        # Limit to nations
        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
  ?x <http://www.w3.org/2004/02/skos/core#prefLabel> ?object_label .
  FILTER regex(?object_label, "^#{country_part}$", "i" )
}}
      elsif state_part.present? && city_part.blank? && country_code == 7012149
        #Limit to states
        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{state_part}$", "i" )

  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/7012149> .
}}
      elsif state_part.present? && city_part.blank?
       #Limit to regions

        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000774>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000772>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300235093>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300135982>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387176>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387122>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{state_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
       ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> ?country_label .
       FILTER regex(?country_label, "^#{country_part}$", "i" )
    }

  }
}
GROUP BY ?object_identifier
}

      elsif state_part.present? && city_part.present? && neighborhood_part.blank?
        #Limited to only inhabited places at the moment...
        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{city_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
       ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> ?country_label .
       FILTER regex(?country_label, "^#{country_part}$", "i" )
    }

  }
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_state .
  {
    SELECT ?parent_state ?identifier_state
    WHERE {
       ?parent_state <http://purl.org/dc/elements/1.1/identifier> ?identifier_state .
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000774>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000772>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300235093>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300135982>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387176>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387122>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
       ?parent_state <http://www.w3.org/2000/01/rdf-schema#label> ?state_label .
       FILTER regex(?state_label, "^#{state_part}$", "i" )
    }

  }

}
GROUP BY ?object_identifier
}
      elsif state_part.present? && city_part.present? && neighborhood_part.present?
        #Limited to only to neighborhoods currently...
        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000745> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{neighborhood_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
       ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> ?country_label .
       FILTER regex(?country_label, "^#{country_part}$", "i" )
    }

  }
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_state .
  {
    SELECT ?parent_state ?identifier_state
    WHERE {
       ?parent_state <http://purl.org/dc/elements/1.1/identifier> ?identifier_state .
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000774>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000772>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300235093>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300135982>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387176>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387122>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
       ?parent_state <http://www.w3.org/2000/01/rdf-schema#label> ?state_label .
       FILTER regex(?state_label, "^#{state_part}$", "i" )
    }

  }

  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_city .
  {
    SELECT ?parent_city ?identifier_city
    WHERE {
       ?parent_city <http://purl.org/dc/elements/1.1/identifier> ?identifier_city .
       ?parent_city <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .
       ?parent_city <http://www.w3.org/2000/01/rdf-schema#label> ?city_label .
       FILTER regex(?city_label, "^#{city_part}$", "i" )
    }

  }

}
GROUP BY ?object_identifier
}


      else
        return nil
      end

      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

       tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})

      end until (tgn_response.code != 500 || retry_count == max_retry)




      unless tgn_response.code == 500
        as_json = JSON.parse(tgn_response.body)

        #This is ugly and needs to be redone to achieve better recursive...
        if as_json["results"]["bindings"].first["object_identifier"].blank?
          if neighborhood_part.present?
            geo_hash[:neighborhood_part] = nil
            geo_hash = tgn_id_from_geo_hash(geo_hash)
          elsif city_part.present?
            geo_hash[:city_part] = nil
            geo_hash = tgn_id_from_geo_hash(geo_hash)
          end

          return nil
        else
          return_hash[:id] = as_json["results"]["bindings"].first["object_identifier"]["value"]
        end
      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + query
      end

      if return_hash.present?
        return_hash[:original_string_differs] = Bplgeo::Standardizer.parsed_and_original_check(geo_hash)
        return return_hash
      else
        return nil
      end
    end


  end
end