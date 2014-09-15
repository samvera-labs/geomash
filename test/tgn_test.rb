require 'test_helper'

class TGNTest < ActiveSupport::TestCase
  def test_tgn_lookup_from_id
    if Bplgeo::TGN.tgn_enabled == 'true'
       result = Bplgeo::TGN.get_tgn_data('2051159')

       assert_equal '45', result[:coords][:latitude]
       assert_equal '-84.1333', result[:coords][:longitude]
       assert_equal '45,-84.1333', result[:coords][:combined]
       assert_equal 'Atlanta', result[:hier_geo][:city]
       assert_equal 'Montmorency', result[:hier_geo][:county]
       assert_equal 'Michigan', result[:hier_geo][:state]
       assert_equal 'United States', result[:hier_geo][:country]
       assert_equal 'North and Central America', result[:hier_geo][:continent]

    end
  end
end