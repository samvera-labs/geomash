# -*- coding: utf-8 -*-
module Geomash
  class Standardizer

    #Take a subject string and look for potential geographic terms.
    def self.parse_for_geographic_term(term)
      geo_term = ''

      #Likely too long to be an address... some fields have junk with an address string...
      if term.length > 125
        return ''
      end

      term_split_list = term.split(/[,\-\(\(]|&gt;/).reject{ |e| e.empty? }
      term_split_list.each{ |e| e.gsub!(/[^\w\s]/, "") } #Remove punctuation
      term_split_list.each{ |e| e.strip! } #Remove any extra remaining whitespace
      term_split_list.reject{ |e| e.empty? }
      state_abbr_list = ['Mass']
      state_name_list = []
      country_name_list = []

      #Countries gem of https://github.com/hexorx/countries
      ISO3166::Country.new('US').states.each do |state_abbr, state_names|
        state_abbr_list << ' ' + state_abbr
        state_name_list << state_names["name"]
      end

      ISO3166::Country.all.each do |country_name_hash|
        #country_name_list << country_name_abbr_pair.first
        country_name_list << country_name_hash.data["name"] if country_name_hash.data["name"].present?
        country_name_hash.data["names"].each do |name|
          country_name_list << name
        end
      end
      country_name_list.append('South Korea') #Listed as Korea, Republic of in the gem
      country_name_list.append('North Korea') #Listed as Korea, Democratic People's Republic Of of in the gem

      #Parsing a subject geographic term.
      if (state_name_list & term_split_list).present? || (state_abbr_list & term_split_list).present? || (country_name_list & term_split_list).present?
        if term.include?('--')
          term.split('--').each_with_index do |split_term, index|
            if state_name_list.any? { |state| split_term.include? state } || country_name_list.any? { |country| split_term.include? country }
              #Cases like Naroden Etnografski Muzeĭ (Sofia, Bulgaria)--Catalogs
              if split_term.match(/\([^\)]+\)/)
                geo_term = split_term.gsub('(', ',').gsub(' ,', ', ')
                geo_term = geo_term.gsub(')', '')

=begin
            if split_term.match(/\([^\)]+,[^\)]+\)/)
              geo_term = split_term.match(/\([^\)]+\)/).to_s
              geo_term = geo_term[1..geo_term.length-2]
            #Abbeville (France)--History--20th century.
            elsif split_term.match(/\([^\)]+\)/)
              geo_term = split_term
=end
              else
                geo_term = term.split('--')[index..term.split('--').length-1].reverse!.join(',')
              end

            elsif state_abbr_list.any? { |abbr| split_term.include? abbr }
              geo_term = split_term
            end
          end
          #Other than a '--' field
          #Experimental... example: Palmer (Mass) - history or Stores (retail trade) - Palmer, Mass
        elsif term.include?(' - ')
          term.split(' - ').each do |split_term|
            if state_name_list.any? { |state| split_term.include? state } || state_abbr_list.any? { |abbr| split_term.include? abbr } || country_name_list.any? { |country| split_term.include? country }
              geo_term = split_term
            end

          end
        else
          #if term_split_list.length > 1
          geo_term = term.gsub('(', ',').gsub(' ,', ', ').gsub(' &gt;', ',')
          geo_term = geo_term.gsub(')', '')
          #end

        end
      end

      return geo_term
    end

    #Make a string in a standard format.
    def self.standardize_geographic_term(geo_term)

      geo_term = geo_term.clone #Don't change original

      #Remove common junk terms
      Geomash::Constants::JUNK_TERMS.each { |term| geo_term.gsub!(term, '') }

      #Strip any leading periods or commas from junk terms
      geo_term = geo_term.gsub(/^[\.,]+/, '').strip

      #Replace any four TGN dashes from removing a junk term
      geo_term = geo_term.gsub('----', '--')

      #Replace any semicolons with commas... possible strip them?
      geo_term = geo_term.gsub(';', ',')

      #Replace &gt; with commas
      geo_term = geo_term.gsub('&gt;', ',').gsub('>', ',')

      #Terms in paranthesis will cause some geographic parsers to freak out. Switch to commas instead.
      if geo_term.match(/[\(\)]+/)
        #Attempt to fix address if something like (word)
        if geo_term.match(/ \(+.*\)+/)
          #Make this replacement better?
          geo_term = geo_term.gsub(/ *\((?=[\S ]+\))/,', ')
          geo_term = geo_term.gsub(')', '')

          #Else skip this as data returned likely will be unreliable for now... FIXME when use case occurs.
        else
          return nil
        end
      end

      geo_term = geo_term.squeeze(',')

      return geo_term
    end

    #Attempt to dedup a list of geographic areas.
    #FIXME: Horrendous first pass.
    #Aggresive flag removes less specific matches. IE. ['Hanoi, Vietnam' and 'Vietnam'] would return just ['Hanoi, Vietnam']
    def self.dedup_geo(geo_list, aggressive=false)
      geo_list = geo_list.clone

       base_word_geo_list = []
       geo_list.each do |geo_term|
         geo_term = geo_term.gsub('(','').gsub(')','').gsub('.','').gsub(',','').gsub(';','')
         #Remove common junk terms
         Geomash::Constants::JUNK_TERMS.each { |term| geo_term.gsub!(term, '') }

         geo_term = geo_term.squish

         base_word_geo_list << geo_term
       end

      indexes_to_remove = []

      0.upto base_word_geo_list.size-1 do |index|
        matched_words_count = []
        current_best_term = geo_list[index]
        current_best_term_index = index

        base_word_geo_list[index].split(' ').each { |word|

          (index+1).upto base_word_geo_list.size-1 do |inner_index|
            if base_word_geo_list[inner_index].split(' ').any? { |single_word| single_word == word }
              matched_words_count[inner_index] ||= 0
              matched_words_count[inner_index] = matched_words_count[inner_index] + 1

            end
          end
        }

        matched_words_count.each_with_index do |matched_count, matched_index|
          matched_count ||= 0

          if (matched_count ==  base_word_geo_list[matched_index].split(' ').size) && ((base_word_geo_list[matched_index].split(' ').size < base_word_geo_list[index].split(' ').size && aggressive) || (base_word_geo_list[matched_index].split(' ').size == base_word_geo_list[index].split(' ').size))
            if current_best_term.split(',').size < geo_list[matched_index].split(',').size || (current_best_term.size+1 < geo_list[matched_index].size && !geo_list[matched_index].include?('('))
              current_best_term =  geo_list[matched_index]
              indexes_to_remove << current_best_term_index
              current_best_term_index = matched_index
            else
              indexes_to_remove << matched_index
            end
          end

        end
      end

      indexes_to_remove.each do |removal_index|
        geo_list[removal_index] = nil
      end

      return geo_list.compact
    end

    def self.parsed_and_original_check(geo_hash)
      term = geo_hash[:standardized_term]

      if geo_hash[:street_part].present? || geo_hash[:coords].present?
        return true
      end

      #Keep original string if three parts at least or if there is a number in the term.
      #TODO: Make this better!
      if (term.split(',').length >= 3 && geo_hash[:neighborhood_part].blank?) || (term.split(',').length >= 2 && geo_hash[:city_part].blank?) || term.split(',').length >= 4 || term.match(/\d/).present?
        return true
      end

      if geo_hash[:country_part] != 'United States'
        if geo_hash[:city_part].blank? && geo_hash[:state_part].blank?
          #Currently do noting
        elsif !((geo_hash[:city_part].present? && term.to_ascii.downcase.include?(geo_hash[:city_part].to_ascii.downcase)) || (geo_hash[:state_part].present? && term.to_ascii.downcase.include?(geo_hash[:state_part].to_ascii.downcase)))
         return true
        end
      end


      return false
    end



    #Take LCSH subjects and make them standard.
    def self.LCSHize(value)
      #Remove ending periods ... except when an initial or etc.
      if value.last == '.' && value[-2].match(/[^A-Z]/) && !value[-4..-1].match('etc.')
        value = value.slice(0..-2)
      end

      #Fix when '- -' occurs
      value = value.gsub(/-\s-/,'--')

      #Fix for "em" dashes - two types?
      value = value.gsub('—','--')

      #Fix for "em" dashes - two types?
      value = value.gsub('–','--')

      #Fix for ' - ' combinations
      value = value.gsub(' - ','--')

      #Remove white space after and before  '--'
      value = value.gsub(/\s+--/,'--')
      value = value.gsub(/--\s+/,'--')

      #Ensure first work is capitalized
      value[0] = value.first.capitalize[0]

      #Strip any white space
      value = strip_value(value)

      return value
    end

    def self.strip_value(value)
      if(value.blank?)
        return nil
      else
        if value.class == Float || value.class == Fixnum
          value = value.to_i.to_s
        end

        # Make sure it is all UTF-8 and not character encodings or HTML tags and remove any cariage returns
        return utf8Encode(value)
      end
    end

    #TODO: Better name for this. Should be part of an overall helped gem.
    def self.utf8Encode(value)
      return HTMLEntities.new.decode(ActionView::Base.full_sanitizer.sanitize(value.to_s.gsub(/\r?\n?\t/, ' ').gsub(/\r?\n/, ' ').gsub(/<br[\s]*\/>/,' '))).strip
    end


    def self.try_with_entered_names(geo_hash)
      geo_hash_local = geo_hash.clone
      geo_hash_local[:tgn] = nil
      if geo_hash_local[:neighborhood_part].present?
         orig_string_check = geo_hash_local[:standardized_term].gsub(',', ' ').squish.split(' ').select { |value| value.downcase.to_ascii == geo_hash_local[:neighborhood_part].downcase.to_ascii}
         geo_hash_local[:neighborhood_part] = orig_string_check.first.strip if orig_string_check.present? && orig_string_check != geo_hash_local[:neighborhood_part]
         return geo_hash_local
      end

      if geo_hash_local[:city_part].present?
        orig_string_check = geo_hash_local[:standardized_term].gsub(',', ' ').squish.split(' ').select { |value| value.downcase.to_ascii == geo_hash_local[:city_part].downcase.to_ascii}
        geo_hash_local[:city_part] = orig_string_check.first.strip if orig_string_check.present?
        return geo_hash_local
      end


      if geo_hash_local[:state_part].present?
        orig_string_check = geo_hash_local[:standardized_term].gsub(',', ' ').squish.split(' ').select { |value| value.downcase.to_ascii == geo_hash_local[:state_part].downcase.to_ascii}
        geo_hash_local[:state_part] = orig_string_check.first.strip if orig_string_check.present?
        return geo_hash_local
      end

      return nil
    end

  end
end
