# frozen_string_literal: true

module Geomash
  class TownLookup
    #Only returns one result for now...
    #Need to avoid cases like "Boston" and "East Boston"
    def self.state_town_lookup(state_key, string)
      return_tgn_id = nil
      matched_terms_count = 0
      matching_towns = Geomash::Constants::STATE_TOWN_TGN_IDS[state_key.to_sym].select {|hash| string.include?(hash[:location_name])}
      matching_towns.each do |matching_town|
        if matching_town[:location_name].split(' ').length > matched_terms_count
          return_tgn_id = matching_town[:tgn_id]
          matched_terms_count = matching_town[:location_name].split(' ').length
        end
      end

      return_tgn_id
    end
  end
end
