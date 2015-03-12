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

      primary_tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/download/json", :params=>{:uri=>"http://vocab.getty.edu/tgn/#{tgn_id}.json"}, :timeout=>500)

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

        primary_tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :body=>{:query=>query}, :timeout=>500)
        as_json_tgn_response = JSON.parse(primary_tgn_response.body)
      end

      as_json_tgn_response['results']['bindings'].each do |ntriple|
        case ntriple['Predicate']['value']
          when 'http://www.w3.org/2004/02/skos/core#prefLabel'
            if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
              tgn_main_term_info[:label_en] ||= ntriple['Object']['value']
            elsif  ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'zh-latn-pinyin'
              tgn_main_term_info[:label_other] ||= ntriple['Object']['value']
            elsif ntriple['Object']['xml:lang'].blank?
              tgn_main_term_info[:label_default] ||= ntriple['Object']['value']
            else
              tgn_main_term_info[:label_remaining] ||= ntriple['Object']['value']
            end
          when 'http://www.w3.org/2004/02/skos/core#altLabel'
            if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
              tgn_main_term_info[:label_alt] ||= ntriple['Object']['value']
            end
          when 'http://vocab.getty.edu/ontology#placeTypePreferred'
            tgn_main_term_info[:aat_place] ||= ntriple['Object']['value']
          when 'http://schema.org/latitude'
            tgn_main_term_info[:latitude] ||= ntriple['Object']['value']
          when 'http://schema.org/longitude'
            tgn_main_term_info[:longitude] ||= ntriple['Object']['value']
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
      non_hier_geo = {}

      #Default term to best label language...
      tgn_term = tgn_main_term_info[:label_en]
      tgn_term ||= tgn_main_term_info[:label_default]
      tgn_term ||= tgn_main_term_info[:label_other]
      tgn_term ||= tgn_main_term_info[:label_alt]
      tgn_term ||= tgn_main_term_info[:label_remaining]

      tgn_term_type = tgn_main_term_info[:aat_place].split('/').last

      #Initial Term
      if tgn_term.present? && tgn_term_type.present?
        case tgn_term_type
          when '300128176' #continent
            hier_geo[:continent] = tgn_term
          when '300128207', '300387130', '300387506' #nation, autonomous areas, countries
            hier_geo[:country] = tgn_term
          when '300000774' #province
            hier_geo[:province] = tgn_term
          when '300236112', '300182722', '300387194', '300387052', '300387113', '300387107' #region, union, semi-independent political entity, autonomous communities, autonomous regions
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
          when '300000771', '300387092', '300387071' #county, parishes, unitary authorities
            hier_geo[:county] = tgn_term
          when '300008347', '300008389' #inhabited place, cities
            hier_geo[:city] = tgn_term
          when '300000745', '300000778', '300387331' #neighborhood, parishes, parts of inhabited places
            hier_geo[:city_section] = tgn_term
          when '300008791', '300387062' #island
            hier_geo[:island] = tgn_term
          when '300387575', '300387346', '300167671', '300387178', '300387082', '300387173', '300055621', '300386853', '300386831', '300386832', '300008178', '300008804', '300387131', '300132348', '300387085', '300387198', '300008761'   #'81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division', administrative divisions, area (measurement), island groups, mountain ranges, mountain systems, nature reserves, peninsulas, regional divisions, sand bars, senatorial districts (administrative districts), third level subdivisions (political entities), valleys (landforms)
            hier_geo[:area] = tgn_term
          when '300386699' #Top level element of World
            non_hier_geo[:value] = 'World'
            non_hier_geo[:qualifier] = nil
          else
            aat_main_term_info = {}
            label_remaining_check = false

            aat_type_response = Typhoeus::Request.get("http://vocab.getty.edu/download/json", :params=>{:uri=>"http://vocab.getty.edu/aat/#{tgn_term_type}.json"}, :timeout=>500)
            JSON.parse(aat_type_response.body)['results']['bindings'].each do |ntriple|
              case ntriple['Predicate']['value']
                when 'http://www.w3.org/2004/02/skos/core#prefLabel'
                  if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
                    aat_main_term_info[:label_en] ||= ntriple['Object']['value']
                  elsif ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en-us'
                    aat_main_term_info[:label_en] ||= ntriple['Object']['value']
                  elsif  ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'zh-latn-pinyin'
                    aat_main_term_info[:label_other] ||= ntriple['Object']['value']
                  elsif ntriple['Object']['xml:lang'].blank?
                    aat_main_term_info[:label_default] ||= ntriple['Object']['value']
                  else
                    label_remaining_check = true if aat_main_term_info[:label_remaining].present?
                    aat_main_term_info[:label_remaining] ||= ntriple['Object']['value']
                  end
                when 'http://www.w3.org/2004/02/skos/core#altLabel'
                  if ntriple['Object']['xml:lang'].present? &&  ntriple['Object']['xml:lang'] == 'en'
                    aat_main_term_info[:label_alt] ||= ntriple['Object']['value']
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

            if (aat_term =~ /ies$/).present?
              aat_term = aat_term.gsub(/ies$/, 'y')
            elsif (aat_term =~ /es$/).present?
              aat_term = aat_term.gsub(/es$/, '')
            elsif (aat_term =~ /s$/).present?
              aat_term = aat_term.gsub(/s$/, '')
            end

            #Fix cases like "Boston Harbor" as "Boston Harbor (harbor)" isn't that helpful
            non_hier_geo[:value] = tgn_term
            non_hier_geo[:qualifier] = tgn_term.downcase.include?(aat_term.downcase) ? nil : aat_term
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

          tgn_response_for_aat = Typhoeus::Request.post("http://vocab.getty.edu/sparql.json", :body=>{:query=>query}, :timeout=>500)
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
              when '300128207', '300387130', '300387506' #nation, autonomous areas, countries
                hier_geo[:country] = tgn_term
              when '300000774' #province
                hier_geo[:province] = tgn_term
              when '300236112', '300182722', '300387194', '300387052', '300387113', '300387107' #region, union, semi-independent political entity, autonomous communities, autonomous regions
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
              when '300000771', '300387092', '300387071' #county, parishes, unitary authorities
                hier_geo[:county] = tgn_term
              when '300008347', '300008389' #inhabited place, cities
                hier_geo[:city] = tgn_term
              when '300000745', '300000778', '300387331' #neighborhood, parishes, parts of inhabited places
                hier_geo[:city_section] = tgn_term
              when '300008791', '300387062' #island
                hier_geo[:island] = tgn_term
              when '300387575', '300387346', '300167671', '300387178', '300387082', '300387173', '300055621', '300386853', '300386831', '300386832', '300008178', '300008804', '300387131', '300132348', '300387085', '300387198', '300008761'   #'81101/area', '22101/general region', '83210/deserted settlement', '81501/historical region', '81126/national division', administrative divisions, area (measurement), island groups, mountain ranges, mountain systems, nature reserves, peninsulas, regional divisions, sand bars, senatorial districts (administrative districts), third level subdivisions (political entities), valleys (landforms)
                hier_geo[:area] = tgn_term
            end
          end
        end

        tgn_data = {}
        tgn_data[:coords] = coords
        tgn_data[:hier_geo] = hier_geo.length > 0 ? hier_geo : nil
        tgn_data[:non_hier_geo] = non_hier_geo.present? ? non_hier_geo : nil

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
      country_response = {}
      states_response = {}
      cities_response = {}
      neighboorhood_response = {}

      state_part = geo_hash[:state_part]

      country_code = Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_id] unless Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_code ||= ''


      country_part = Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]][:tgn_country_name] unless Geomash::Constants::COUNTRY_TGN_LOOKUP[geo_hash[:country_part]].blank?
      country_part = geo_hash[:country_part] if country_part.blank?
      country_part ||= ''

      city_part = geo_hash[:city_part]

      neighborhood_part = geo_hash[:neighborhood_part]

      web_request_error = false
      begin
        if retry_count > 0
          sleep(sleep_time)
        end
        retry_count = retry_count + 1

        #First we get county!!

        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300128207> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{country_part}$", "i" )
}
  GROUP BY ?object_identifier
}
        country_response = self.tgn_sparql_request(query)
        return nil if country_response[:id].blank? && !country_response[:errors]
        return_hash[:id] = country_response[:id]
        return_hash[:rdf] = country_response[:rdf]
        return_hash[:parse_depth] = 1
        web_request_error = true if country_response[:errors]

        #United State state query
        if state_part.present? && country_code == 7012149 && !web_request_error
          query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000776>} UNION
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{state_part}$", "i" )

  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/7012149> .
}
  GROUP BY ?object_identifier
}

          states_response = self.tgn_sparql_request(query)
          if states_response[:id].blank? && !states_response[:errors]
            return_hash[:original_string_differs] = true
          else
            return_hash[:id] = states_response[:id]
            return_hash[:rdf] = states_response[:rdf]
            return_hash[:parse_depth] = 2
          end
          web_request_error = true if states_response[:errors]
        end

        #Non United States state query
        #Note: Had to remove   {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347>} UNION as it returned two results
        #for "15. Bezirk (Rudolfsheim-Fünfhaus, Vienna, Austria)--Exhibitions". Correct or not?
        if state_part.present? && country_code != 7012149 && !web_request_error
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
  {?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300387081>} .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{state_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{country_response[:id]}> .
}
GROUP BY ?object_identifier
}

          states_response = self.tgn_sparql_request(query)
          if states_response[:id].blank? && !states_response[:errors]
            return_hash[:original_string_differs] = true
          else
            return_hash[:id] = states_response[:id]
            return_hash[:rdf] = states_response[:rdf]
            return_hash[:parse_depth] = 2
          end
          web_request_error = true if states_response[:errors]
        end

        if states_response[:id].present? && city_part.present? && !web_request_error
          query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300008347> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{city_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{country_response[:id]}> .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{states_response[:id]}> .
}
GROUP BY ?object_identifier
}
          cities_response = self.tgn_sparql_request(query)
          if cities_response[:id].blank? && !cities_response[:errors]
            return_hash[:original_string_differs] = true
          else
            return_hash[:id] = cities_response[:id]
            return_hash[:rdf] = cities_response[:rdf]
            return_hash[:parse_depth] = 3
          end
          web_request_error = true if cities_response[:errors]

        end

      if cities_response[:id].present? && neighborhood_part.present? && !web_request_error
        query = %{SELECT ?object_identifier
WHERE
{
  ?x <http://purl.org/dc/elements/1.1/identifier> ?object_identifier .
  ?x <http://vocab.getty.edu/ontology#placeTypePreferred> <http://vocab.getty.edu/aat/300000745> .
  ?x <http://www.w3.org/2000/01/rdf-schema#label> ?object_label .
  FILTER regex(?object_label, "^#{neighborhood_part}$", "i" )
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{country_response[:id]}> .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{states_response[:id]}> .
  ?x <http://vocab.getty.edu/ontology#broaderPreferredExtended> <http://vocab.getty.edu/tgn/#{cities_response[:id]}> .
}
GROUP BY ?object_identifier
}
        neighborhood_response = self.tgn_sparql_request(query)
        if neighborhood_response[:id].blank? && !neighborhood_response[:errors]
          return_hash[:original_string_differs]=true
        else
          return_hash[:id] = neighborhood_response[:id]
          return_hash[:rdf] = neighborhood_response[:rdf]
          return_hash[:parse_depth] = 4
        end
        web_request_error = true if neighborhood_response[:errors]
      end

      end until (!web_request_error || retry_count == max_retry)

      if return_hash.present?
        return_hash[:original_string_differs] ||= Geomash::Standardizer.parsed_and_original_check(geo_hash)
        return return_hash
      else
        return nil
      end

    end

      def self.tgn_sparql_request(query,method="GET")
        response = {}
        query = query.squish
        if(method=="GET")
          tgn_response = Typhoeus::Request.get("http://vocab.getty.edu/sparql.json", :params=>{:query=>query}, :timeout=>500)
        else
          tgn_response = Typhoeus::Request.post("http://vocab.getty.edu/sparql.json", :params=>{:query=>query}, :timeout=>500)
        end

        if tgn_response.success? && tgn_response.code == 200
          begin
            as_json = JSON.parse(tgn_response.body)
            response[:json] = as_json
            if as_json["results"]["bindings"].present? && as_json["results"]["bindings"].first["object_identifier"].present?
              response[:id] = as_json["results"]["bindings"].first["object_identifier"]["value"]
              response[:rdf] = "http://vocab.getty.edu/tgn/#{response[:id]}.rdf"
            end
            response[:errors] = false
          rescue JSON::ParserError
            response[:json] = nil
            response[:errors] = true
          end
        end

        return response

      end


  end
end
