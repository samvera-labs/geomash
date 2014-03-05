module Bplgeo
  class Standardizer

    #Take a subject string and look for potential geographic terms.
    def self.parse_for_geographic_term(term)
      geo_term = ''

      #Likely too long to be an address... some fields have junk with an address string...
      if term.length > 125
        return nil
      end

      state_abbr_list = ['Mass']
      state_name_list = []

      #Countries gem of https://github.com/hexorx/countries
      Country.new('US').states.each do |state_abbr, state_names|
        state_abbr_list << ' ' + state_abbr
        state_name_list << state_names["name"]
      end

      #Parsing a subject geographic term.
      if term.include?('--')
        term.split('--').each_with_index do |split_term, index|
          if state_name_list.any? { |state| split_term.include? state }
            geo_term = term.split('--')[index..term.split('--').length-1].reverse!.join(',')
          elsif state_abbr_list.any? { |abbr| split_term.include? abbr }
            geo_term = split_term
          end
        end
        #Other than a '--' field
        #Experimental... example: Palmer (Mass) - history or Stores (retail trade) - Palmer, Mass
      elsif term.include?(' - ')
        term.split(' - ').each do |split_term|
          if state_name_list.any? { |state| split_term.include? state } || state_abbr_list.any? { |abbr| split_term.include? abbr }
            geo_term = split_term
          end

        end
      else
        if state_name_list.any? { |state| term.include? state } || state_abbr_list.any? { |abbr| term.include? abbr }
          geo_term = term
        end
      end

      return geo_term
    end

    #Make a string in a standard format.
    def self.standardize_geographic_term(geo_term)

      geo_term = geo_term.clone #Don't change original

      #Remove common junk terms
      Bplgeo::Constants::JUNK_TERMS.each { |term| geo_term.gsub!(term, '') }

      #Strip any leading periods or commas from junk terms
      geo_term = geo_term.gsub(/^[\.,]+/, '').strip

      #Replace any semicolons with commas... possible strip them?
      geo_term = geo_term.gsub(';', ',')

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

      return geo_term
    end

    #Attempt to dedup a list of geographic areas.
    #FIXME: Horrendous first pass.
    #Aggresive flag removes less specific matches. IE. ['Hanoi, Vietnam' and 'Vietnam'] would return just ['Hanoi, Vietnam']
    def self.dedup_geo(geo_list, aggresive=false)
      geo_list = geo_list.clone

       base_word_geo_list = []
       geo_list.each do |geo_term|
         geo_term = geo_term.gsub('(','').gsub(')','').gsub('.','').gsub(',','').gsub(';','')
         #Remove common junk terms
         Bplgeo::Constants::JUNK_TERMS.each { |term| geo_term.gsub!(term, '') }

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
          if matched_count ==  base_word_geo_list[index].split(' ').size && ((base_word_geo_list[matched_index].split(' ').size < base_word_geo_list[index].split(' ').size && aggresive) || (base_word_geo_list[matched_index].split(' ').size == base_word_geo_list[index].split(' ').size))
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

      #Keep original string if three parts at least or if there is a number in the term.
      #TODO: Make this better!
      if (term.split(',').length >= 3 && geo_hash[:neighborhood_part].blank?) || (term.split(',').length >= 2 && geo_hash[:city_part].blank?) || term.split(',').length >= 4 || term.match(/\d/).present?
        geo_hash[:term_differs_from_tgn] = true
      end

      if geo_hash[:country_part] != 'United States'
        if geo_hash[:city_part].blank? && geo_hash[:state_part].blank?
          #Currently do noting
        elsif !((geo_hash[:city_part].present? && term.to_ascii.downcase.include?(geo_hash[:city_part].to_ascii.downcase)) || (geo_hash[:state_part].present? && term.to_ascii.downcase.include?(geo_hash[:state_part].to_ascii.downcase)))
         geo_hash[:term_differs_from_tgn] = true
        end
      end

      return geo_hash
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
  end
end