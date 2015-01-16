# -*- coding: utf-8 -*-
module Geomash
  class TGN

    def self.tgn_enabled
      return Geomash.config[:tgn_enabled] unless Geomash.config[:tgn_enabled].nil?
      return true
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

primary_tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/tgn/#{tgn_id}.json")


  when 'http://vocab.getty.edu/ontology#placeTypePreferred'
    place_type_base[:aat_id] = ntriple['Object']['value']
  when 'http://www.w3.org/2004/02/skos/core#prefLabel'
    if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
      place_type_base[:label_en] = ntriple['Object']['value']
    else if ntriple['Object']['xml:lang'].blank?
     place_type_base[:label_default] = ntriple['Object']['value']


tgn_main_term_info = {}
broader_place_type_list = ["http://vocab.getty.edu/tgn/"#{tgn_id}]

primary_tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/download/json", :params=>{:uri=>"http://vocab.getty.edu/tgn/#{tgn_id}.json"})
as_json_tgn_response = JSON.parse(primary_tgn_response.body)

as_json_tgn_response['results']['bindings'].each do |ntriple|
  case ntriple['Predicate']['value']
  when 'http://www.w3.org/2004/02/skos/core#prefLabel'
    if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
      tgn_main_term_info[:label_en] = ntriple['Object']['value']
    elsif ntriple['Object']['xml:lang'].blank?
     tgn_main_term_info[:label_default] = ntriple['Object']['value']
    end
  when 'http://vocab.getty.edu/ontology#placeTypePreferred'
   tgn_main_term_info[:aat_place] = ntriple['Object']['value']
  when 'http://vocab.getty.edu/ontology#broaderPreferredExtended'
    broader_place_type_list << ntriple['Object']['value']
  end

end

query = "SELECT ?identifier_place ?place_label_default ?place_label_en ?aat_pref WHERE {"

broader_place_type_list.each do |place_uri|
query += %{{<#{place_uri}> <http://purl.org/dc/elements/1.1/identifier> ?identifier_place .
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_en
                 FILTER langMatches( lang(?place_label_en), "en" )
                 }
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_default
                 FILTER langMatches( lang(?place_label_default), "" )
                 }
        <#{place_uri}> <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_pref
       } UNION
     }
end

query = query[0..-12]
query += ". } GROUP BY ?identifier_place ?place_label_default ?place_label_en ?aat_pref"

tgn_response_for_aat = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})
as_json_tgn_response_for_aat = JSON.parse(tgn_response_for_aat.body)

as_json_tgn_response_for_aat["results"]["bindings"].each do |aat_response|
  #aat_response['identifier_place']['value']
  #aat_response['place_label_default']['value']
  #....
end





EXAMPLE SPARQL:

    SELECT ?identifier_place ?place_label_default ?place_label_en ?aat_pref
    WHERE {
       {<http://vocab.getty.edu/tgn/1000001> <http://purl.org/dc/elements/1.1/identifier> ?identifier_place .
        OPTIONAL {<http://vocab.getty.edu/tgn/1000001> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_en
                 FILTER langMatches( lang(?place_label_en), "en" )
                 }
        OPTIONAL {<http://vocab.getty.edu/tgn/1000001> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_default
                 FILTER langMatches( lang(?place_label_default), "" )
                 }
        <http://vocab.getty.edu/tgn/1000001> <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_pref
       } UNION
       {<http://vocab.getty.edu/tgn/7012149> <http://purl.org/dc/elements/1.1/identifier> ?identifier_place .
        OPTIONAL {<http://vocab.getty.edu/tgn/7012149> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_en
                 FILTER langMatches( lang(?place_label_en), "en" )
                 }
        OPTIONAL {<http://vocab.getty.edu/tgn/7012149> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_default
                 FILTER langMatches( lang(?place_label_default), "" )
                 }
       <http://vocab.getty.edu/tgn/7012149> <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_pref
       } UNION
       {<http://vocab.getty.edu/tgn/7029392> <http://purl.org/dc/elements/1.1/identifier> ?identifier_place .
        OPTIONAL {<http://vocab.getty.edu/tgn/7029392> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_en
                 FILTER langMatches( lang(?place_label_en), "en" )
                 }
        OPTIONAL {<http://vocab.getty.edu/tgn/7029392> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_default
                 FILTER langMatches( lang(?place_label_default), "" )
                 }
       <http://vocab.getty.edu/tgn/7012149> <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_pref
       } .


    }
   GROUP BY ?identifier_place ?place_label_default ?place_label_en ?aat_pref




=end

    def self.get_tgn_data(tgn_id)
      return nil if Geomash::TGN.tgn_enabled != true

      tgn_id = tgn_id.strip

      tgn_main_term_info = {}
      broader_place_type_list = []

      primary_tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/download/json", :params=>{:uri=>"http://vocab.getty.edu/tgn/#{tgn_id}.json"})

      return nil if(primary_tgn_response.response_code == 404) #Couldn't find TGN... FIXME: additional check needed if TGN is down?

      as_json_tgn_response = JSON.parse(primary_tgn_response.body)

      #There is a bug with some TGN JSON files currently. Example: http://vocab.getty.edu/tgn/7014203.json . Per an email
      # with Getty, this is a hackish workaround for now.
      if(as_json_tgn_response['results'].blank?)
        query = %{
          PREFIX tgn: <http://vocab.getty.edu/tgn/>
          PREFIX gvp: <http://vocab.getty.edu/ontology#>
      PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
      PREFIX dct: <http://purl.org/dc/terms/>
          PREFIX bibo: <http://purl.org/ontology/bibo/>
          PREFIX skosxl: <http://www.w3.org/2008/05/skos-xl#>
      PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
      PREFIX iso: <http://purl.org/iso25964/skos-thes#>
      PREFIX foaf: <http://xmlns.com/foaf/0.1/>
          PREFIX schema: <http://schema.org/>
          CONSTRUCT {
            ?s  ?p1 ?o1.
            ?ac ?p2 ?o2.
            ?t  ?p3 ?o3.
            ?ss ?p4 ?o4.
            ?ts ?p6 ?o6.
            ?st ?p7 ?o7.
            ?ar ?p8 ?o8.
            ?l1 ?p9 ?o9.
            ?l2 ?pA ?oA.
            ?pl ?pB ?oB.
            ?ge ?pC ?oC.
          } WHERE {
        BIND (tgn:#{tgn_id} as ?s)
        {?s ?p1 ?o1 FILTER(!isBlank(?o1) &&
            !(?p1 in (gvp:narrowerExtended, skos:narrowerTransitive, skos:semanticRelation)))}
      UNION {?s skos:changeNote ?ac. ?ac ?p2 ?o2}
      UNION {?s dct:source ?ss. ?ss a bibo:DocumentPart. ?ss ?p4 ?o4}
      UNION {?s skos:scopeNote|skosxl:prefLabel|skosxl:altLabel ?t.
                                                                {?t ?p3 ?o3 FILTER(!isBlank(?o3))}
      UNION {?t dct:source ?ts. ?ts a bibo:DocumentPart. ?ts ?p6 ?o6}}
      UNION {?st rdf:subject ?s. ?st ?p7 ?o7}
      UNION {?s skos:member/^rdf:first ?l1. ?l1 ?p9 ?o9}
      UNION {?s iso:subordinateArray ?ar FILTER NOT EXISTS {?ar skosxl:prefLabel ?t1}.
                                                    {?ar ?p8 ?o8}
      UNION {?ar skos:member/^rdf:first ?l2. ?l2 ?pA ?oA}}
      UNION {?s foaf:focus ?pl.
      {?pl ?pB ?oB}
      UNION {?pl schema:geo ?ge. ?ge ?pC ?oC}}
      }
      }

        query = query.squish

        primary_tgn_response = Typhoeus::Request.post("http://vocab.getty.edu/sparql.json", :body=>{:query=>query})
        as_json_tgn_response = JSON.parse(primary_tgn_response.body)
      end

      #FIXME: Temporary hack to determine more cases of non-blank/english place name conflicts that require resolution.
      label_remaining_check = false

      as_json_tgn_response['results']['bindings'].each do |ntriple|
        case ntriple['Predicate']['value']
          when 'http://www.w3.org/2004/02/skos/core#prefLabel'
            if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
              tgn_main_term_info[:label_en] = ntriple['Object']['value']
            elsif  ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'zh-latn-pinyin'
              tgn_main_term_info[:label_other] = ntriple['Object']['value']
            elsif ntriple['Object']['xml:lang'].blank?
              tgn_main_term_info[:label_default] = ntriple['Object']['value']
            else
              label_remaining_check = true if tgn_main_term_info[:label_remaining].present?
              tgn_main_term_info[:label_remaining] = ntriple['Object']['value']
            end
          when 'http://www.w3.org/2004/02/skos/core#altLabel'
            if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
              tgn_main_term_info[:label_alt] = ntriple['Object']['value']
            end
          when 'http://vocab.getty.edu/ontology#placeTypePreferred'
            tgn_main_term_info[:aat_place] = ntriple['Object']['value']
          when 'http://schema.org/latitude'
            tgn_main_term_info[:latitude] = ntriple['Object']['value']
          when 'http://schema.org/longitude'
            tgn_main_term_info[:longitude] = ntriple['Object']['value']
          when 'http://vocab.getty.edu/ontology#broaderPreferredExtended'
            broader_place_type_list << ntriple['Object']['value']
        end

      end

      # coordinates
      coords = nil
      if tgn_main_term_info[:latitude].present?
        coords = {}
        coords[:latitude] = tgn_main_term_info[:latitude]
        coords[:longitude] = tgn_main_term_info[:longitude]
        coords[:combined] = tgn_main_term_info[:latitude] + ',' + tgn_main_term_info[:longitude]
      end

      hier_geo = {}
      #Default term to best label language...
      tgn_term = tgn_main_term_info[:label_en]
      tgn_term ||= tgn_main_term_info[:label_default]
      tgn_term ||= tgn_main_term_info[:label_other]
      tgn_term ||= tgn_main_term_info[:label_alt]
      if tgn_term.blank?
        if label_remaining_check
          raise "Could not determine a single label for TGN: " + tgn_id
        else
          tgn_term = tgn_main_term_info[:label_remaining]
        end
      end

      tgn_term_type = tgn_main_term_info[:aat_place].split('/').last

      #Initial Term
      if tgn_term.present? && tgn_term_type.present?
        case tgn_term_type
          when '300128176' #continent
            hier_geo[:continent] ||= tgn_term
          when '300128207' #nations
            hier_geo[:country] ||= tgn_term
          when '300000774' #province
            hier_geo[:province] ||= tgn_term
          when '300236112', '300182722', '300387194', '300387052' #region, union, semi-independent political entity
            hier_geo[:region] ||= tgn_term
          when '300000776', '300000772', '300235093' #state, department, governorate
            hier_geo[:state] ||= tgn_term
          when '300387081' #national district
            if tgn_term == 'District of Columbia'
              hier_geo[:state] ||= tgn_term
            else
              hier_geo[:territory] ||= tgn_term
            end
          when '300135982', '300387176', '300387122' #territory, dependent state, union territory
            hier_geo[:territory] ||= tgn_term
          when '300000771' #county
            hier_geo[:county] ||= tgn_term
          when '300008347', '300387068' #inhabited place, independent cities
            hier_geo[:city] ||= tgn_term
          when '300000745' #neighborhood
            hier_geo[:city_section] ||= tgn_term
          when '300008791', '300387062' #island
            hier_geo[:island] ||= tgn_term
          when '300387575', '300387346', '300167671', '300387178', '300387082' #'81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division'
            hier_geo[:area] ||= tgn_term
          else
            #Get the type... excluding top level elements (like World)
            if tgn_term_type != '300386699'
              aat_main_term_info = {}
              label_remaining_check = false

              aat_type_response = Typhoeus::Request.get("http://vocab.getty.edu/download/json", :params=>{:uri=>"http://vocab.getty.edu/aat/#{tgn_term_type}.json"})
              JSON.parse(aat_type_response.body)['results']['bindings'].each do |ntriple|
                case ntriple['Predicate']['value']
                  when 'http://www.w3.org/2004/02/skos/core#prefLabel'
                    if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
                      aat_main_term_info[:label_en] ||= ntriple['Object']['value']
                    elsif ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en-us'
                      aat_main_term_info[:label_en] = ntriple['Object']['value']
                    elsif  ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'zh-latn-pinyin'
                      aat_main_term_info[:label_other] = ntriple['Object']['value']
                    elsif ntriple['Object']['xml:lang'].blank?
                      aat_main_term_info[:label_default] = ntriple['Object']['value']
                    else
                      label_remaining_check = true if aat_main_term_info[:label_remaining].present?
                      aat_main_term_info[:label_remaining] = ntriple['Object']['value']
                    end
                  when 'http://www.w3.org/2004/02/skos/core#altLabel'
                    if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
                      aat_main_term_info[:label_alt] = ntriple['Object']['value']
                    end
                end

              end
              #Default term to best label language...
              aat_term = aat_main_term_info[:label_en]
              aat_term ||= aat_main_term_info[:label_default]
              aat_term ||= aat_main_term_info[:label_other]
              aat_term ||= aat_main_term_info[:label_alt]

              if aat_term.blank?
                if label_remaining_check
                  raise "Could not determine a single aat non_hier_geo label for TGN: " + tgn_id
                else
                  aat_term = aat_main_term_info[:label_remaining]
                end
              end

              #Fix cases like http://vocab.getty.edu/aat/300132316 which are bays (bodies of water)
              aat_term = aat_term.gsub(/ \(.+\)$/, '')
              aat_term = aat_term.gsub(/s$/, '')

              #Fix cases like "Boston Harbor" as "Boston Harbor (harbor)" isn't that helpful
              non_hier_geo = tgn_term.downcase.include?(aat_term.downcase) ? tgn_term : "#{tgn_term} (#{aat_term})"
            else
              non_hier_geo = tgn_term
            end

        end

        #Broader places
        #FIXME: could parse xml:lang instead of the three optional clauses now... didn't expect places to lack a default preferred label.
        if broader_place_type_list.present? #Case of World... top of hierachy check
          query = "SELECT ?identifier_place ?place_label_default ?place_label_en ?place_label_remaining ?aat_pref WHERE {"

          broader_place_type_list.each do |place_uri|
            query += %{{<#{place_uri}> <http://purl.org/dc/elements/1.1/identifier> ?identifier_place .
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_en
                 FILTER langMatches( lang(?place_label_en), "en" )
                 }
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_default
                 FILTER langMatches( lang(?place_label_default), "" )
                 }
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_latn_pinyin
                 FILTER langMatches( lang(?place_label_latn_pinyin), "zh-latn-pinyin" )
                 }
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#altLabel> ?place_label_alt
                 FILTER langMatches( lang(?place_label_alt), "en" )
                 }
        OPTIONAL {<#{place_uri}> <http://www.w3.org/2004/02/skos/core#prefLabel> ?place_label_remaining
                 FILTER(!langMatches( lang(?place_label_remaining), "" ) && !langMatches( lang(?place_label_remaining), "en" ) && !langMatches( lang(?place_label_remaining), "zh-latn-pinyin" ))
                 }
        <#{place_uri}> <http://vocab.getty.edu/ontology#placeTypePreferred> ?aat_pref
       } UNION
     }
          end

          query = query[0..-12]
          query += ". } GROUP BY ?identifier_place ?place_label_default ?place_label_en ?place_label_latn_pinyin ?place_label_alt ?place_label_remaining ?aat_pref"
          query = query.squish

          tgn_response_for_aat = Typhoeus::Request.post("http://vocab.getty.edu/sparql.json", :body=>{:query=>query})
          as_json_tgn_response_for_aat = JSON.parse(tgn_response_for_aat.body)

          as_json_tgn_response_for_aat["results"]["bindings"].each do |aat_response|
            tgn_term_type = aat_response['aat_pref']['value'].split('/').last

            if aat_response['place_label_en'].present? && aat_response['place_label_en']['value'] != '-'
              tgn_term = aat_response['place_label_en']['value']
            elsif aat_response['place_label_default'].present? && aat_response['place_label_default']['value'] != '-'
              tgn_term = aat_response['place_label_default']['value']
            elsif aat_response['place_label_latn_pinyin'].present? && aat_response['place_label_latn_pinyin']['value'] != '-'
              tgn_term = aat_response['place_label_latn_pinyin']['value']
            elsif aat_response['place_label_alt'].present? && aat_response['place_label_alt']['value'] != '-'
              tgn_term = aat_response['place_label_alt']['value']
            else
              tgn_term = aat_response['place_label_remaining']['value']
            end

            case tgn_term_type
              when '300128176' #continent
                hier_geo[:continent] = tgn_term
              when '300128207' #nation
                hier_geo[:country] = tgn_term
              when '300000774' #province
                hier_geo[:province] = tgn_term
              when '300236112', '300182722', '300387194', '300387052' #region, union, semi-independent political entity
                hier_geo[:region] = tgn_term
              when '300000776', '300000772', '300235093' #state, department, governorate
                hier_geo[:state] = tgn_term
              when '300387081' #national district
                if tgn_term == 'District of Columbia'
                  hier_geo[:state] = tgn_term
                else
                  hier_geo[:territory] = tgn_term
                end
              when '300135982', '300387176', '300387122' #territory, dependent state, union territory
                hier_geo[:territory] = tgn_term
              when '300000771' #county
                hier_geo[:county] = tgn_term
              when '300008347' #inhabited place
                hier_geo[:city] = tgn_term
              when '300000745' #neighborhood
                hier_geo[:city_section] = tgn_term
              when '300008791', '300387062' #island
                hier_geo[:island] = tgn_term
              when '300387575', '300387346', '300167671', '300387178', '300387082' #'81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division'
                hier_geo[:area] = tgn_term
            end
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
      return nil if Geomash::TGN.tgn_enabled != true

      geo_hash = geo_hash.clone

      max_retry = 3
      sleep_time = 60 # In seconds
      retry_count = 0

      return_hash = {}

      state_part = geo_hash[:state_part]

      country_code = Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_id] unless Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_code ||= ''


      country_part = Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_country_name] unless Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
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
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300236112>} UNION
  {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347>} UNION
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

        #FIXME Temporary: For Geomash.parse('Aknīste (Latvia)', true), seems to be a neighborhood placed in state
        # {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347>} UNION
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
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300236112>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347>} UNION
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
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300236112>} UNION
       {?parent_state <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347>} UNION
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

      query = query.squish
       tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query})

      end until (tgn_response.code != 500 || retry_count == max_retry)




      unless tgn_response.code == 500
        as_json = JSON.parse(tgn_response.body)

        #This is ugly and needs to be redone to achieve better recursive...
        if as_json["results"]["bindings"].present? && as_json["results"]["bindings"].first["object_identifier"].present?
          return_hash[:id] = as_json["results"]["bindings"].first["object_identifier"]["value"]
          return_hash[:rdf] = "http://vocab.getty.edu/tgn/#{return_hash[:id]}.rdf"
        else
          return nil
        end
      end

      if tgn_response.code == 500
        raise 'TGN Server appears to not be responding for Geographic query: ' + query
      end

      if return_hash.present?
        return_hash[:original_string_differs] = Geomash::Standardizer.parsed_and_original_check(geo_hash)
        return return_hash
      else
        return nil
      end
    end


  end
end
