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

      top_match_term = ''
      match_term = nil

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


=end

=begin
Broader (Suffolk of Boston):
<http://vocab.getty.edu/tgn/7013445> <http://www.w3.org/2004/02/skos/core#broader> <http://vocab.getty.edu/tgn/1002923> .


http://vocab.getty.edu/sparql?query=SELECT+%3Ftitle%0D%0AWHERE%0D%0A%7B%0D%0A++%3Chttp%3A%2F%2Fvocab.getty.edu%2Ftgn%2F7013445%3E+%3Chttp%3A%2F%2Fpurl.org%2Fdc%2Felements%2F1.1%2Fidentifier%3E+%3Ftitle+.%0D%0A++%3Chttp%3A%2F%2Fvocab.getty.edu%2Ftgn%2F7013445%3E+%3Chttp%3A%2F%2Fvocab.getty.edu%2Fontology%23placeTypePreferred%3E+%3Chttp%3A%2F%2Fvocab.getty.edu%2Faat%2F300008347%3E+.%0D%0A%7D&_implicit=false&implicit=true&_equivalent=false&_form=%2Fsparql

http://vocab.getty.edu/sparql.json?query=SELECT+%3Ftitle%0D%0AWHERE%0D%0A%7B%0D%0A++%3Chttp%3A%2F%2Fvocab.getty.edu%2Ftgn%2F7013445%3E+%3Chttp%3A%2F%2Fpurl.org%2Fdc%2Felements%2F1.1%2Fidentifier%3E+%3Ftitle+.%0D%0A++%3Chttp%3A%2F%2Fvocab.getty.edu%2Ftgn%2F7013445%3E+%3Chttp%3A%2F%2Fvocab.getty.edu%2Fontology%23placeTypePreferred%3E+%3Chttp%3A%2F%2Fvocab.getty.edu%2Faat%2F300008347%3E+.%0D%0A%7D&_implicit=false&implicit=true&_equivalent=false&_form=%2Fsparql



query = %{SELECT ?title
WHERE
{
  <http://vocab.getty.edu/tgn/7013445> <http://purl.org/dc/elements/1.1/identifier> ?title .
  <http://vocab.getty.edu/tgn/7013445> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .
}}

 response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})


# EXAMPLE FOR COUNTRIES

country = "United States"

query = %{SELECT ?identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
  {?x <http://www.w3.org/2004/02/skos/core#prefLabel> "#{country}"@en} UNION {?x <http://www.w3.org/2004/02/skos/core#prefLabel> "#{country}"} .
}}

 response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})
as_json = JSON.parse(response.body)
as_json["results"]["bindings"].first["identifier"]["value"]   #FIRST could be blank or list


# EXAMPLE FOR STATES

country = "United States"
state = "South Carolina"

query = %{SELECT ?identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776> .
  {?x <http://www.w3.org/2004/02/skos/core#prefLabel> "#{state}"@en} UNION {?x <http://www.w3.org/2004/02/skos/core#prefLabel> "#{state}"} .
  ?x <http://vocab.getty.edu/ontology#parentString> ?parent_string .
  FILTER regex(?parent_string, "#{country},", "i" )
}}

response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})



# EXAMPLE FOR REGIONS - use TGN 7001070 as start

country = "Việt Nam"
state = "Hà So'n Bình, Tỉnh"

query = %{SELECT ?identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?identifier .
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000774>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000772>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300235093>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300135982>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387176>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387122>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{state}"@en} UNION {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{state}"} .
  ?x <http://vocab.getty.edu/ontology#parentString> ?parent_string .
  FILTER regex(?parent_string, "#{country},", "i" )
}}

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
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{state}"@en} UNION {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{state}"} .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
      { ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> "#{country}"@en} UNION {?parent_country <http://www.w3.org/2000/01/rdf-schema#label> "#{country}"} .
    }
  }
}}

(broken due to @vi... need to make optional maybe?)


SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000774>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000772>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300235093>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300135982>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387176>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387122>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  {?x <http://www.w3.org/2000/01/rdf-schema#label> "Hà So'n Bình, Tỉnh"@en} UNION {?x <http://www.w3.org/2000/01/rdf-schema#label> "Hà So'n Bình, Tỉnh"} .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> ?parent_country .
  {
    SELECT ?parent_country ?identifier_country
    WHERE {
       ?parent_country <http://purl.org/dc/elements/1.1/identifier> ?identifier_country .
       ?parent_country <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
      { ?parent_country <http://www.w3.org/2000/01/rdf-schema#label> "Viet Nam"@en} UNION {?parent_country <http://www.w3.org/2000/01/rdf-schema#label> "Viet Nam"} .
    }
  }
}

response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})

# EXAMPLE FOR CITIES

country = "Việt Nam"
state = "Hà So'n Bình, Tỉnh"
city = "Hà Nội"

query = %{SELECT ?identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?identifier .
  <http://vocab.getty.edu/tgn/7013445> <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .
  {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{city}"@en} UNION {?x <http://www.w3.org/2000/01/rdf-schema#label> "#{city}"} .
  ?x <http://vocab.getty.edu/ontology#parentString> ?parent_string .
  FILTER regex(?parent_string, "#{country},", "i" )
}}





# 5.1.6 Full Text Search Query
PREFIX luc: <http://www.ontotext.com/owlim/lucene#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX gvp: <http://vocab.getty.edu/ontology#>
PREFIX skosxl: <http://www.w3.org/2008/05/skos-xl#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX dct: <http://purl.org/dc/terms/>
PREFIX gvp_lang: <http://vocab.getty.edu/language/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
SELECT ?Subject ?Term ?Parents ?ScopeNote ?Type {
  ?Subject luc:term "Boston"; a ?typ.
  ?typ rdfs:subClassOf gvp:Subject; rdfs:label ?Type.
  optional {?Subject gvp:prefLabelGVP [skosxl:literalForm ?Term]}
  optional {?Subject gvp:parentStringAbbrev ?Parents}
  optional {?Subject skos:scopeNote [dct:language gvp_lang:en; rdf:value ?ScopeNote]}}




=end


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
        return nil
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

          return nil
        end

        #If only one result, then not array. Otherwise array....
        if parsed_xml.Vocabulary.Subject.first.blank?
          subject = parsed_xml.Vocabulary.Subject

          current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
          alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

          #FIXME: Term should check for the correct level... temporary fix...
          if current_term == match_term && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            return_hash[:id] = subject.Subject_ID.text
          #Check alternative term ids
          elsif alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            return_hash[:id] = subject.Subject_ID.text
          elsif current_term == match_term && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            return_hash[:id] = subject.Subject_ID.text
          elsif alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
            return_hash[:id] = subject.Subject_ID.text
          end
        else
         parsed_xml.Vocabulary.Subject.each do |subject|

            current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
            alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

            if current_term == match_term && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
              return_hash[:id] = subject.Subject_ID.text
            end
          end

          if return_hash[:id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                return_hash[:id] = subject.Subject_ID.text
              end
            end
          end

          if return_hash[:id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if current_term == match_term && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                return_hash[:id] = subject.Subject_ID.text
              end
            end
          end

          if return_hash[:id].blank?
            parsed_xml.Vocabulary.Subject.each do |subject|
              current_term = subject.Preferred_Term.text.gsub(/\(.*\)/, '').to_ascii.downcase.strip
              alternative_terms = subject.elements.any? { |node| node.name == 'Term' } ? subject.Term : ''

              if alternative_terms.present? && alternative_terms.children.any? { |alt_term| alt_term.text.to_ascii.downcase.strip == match_term} && second_top_match_term.any? { |top_match| subject.Preferred_Parent.text.to_ascii.downcase.include? top_match }
                return_hash[:id] = subject.Subject_ID.text
              end
            end
          end
        end

      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + term
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