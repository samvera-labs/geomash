require 'test_helper'

class BplgeoTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, Bplgeo
  end

  def test_parse
    result = Bplgeo.parse('Boston, MA')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal '7013445', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('New York, NY')
    assert_equal 'New York', result[:city_part]
    assert_equal 'New York', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal '7007567', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('Washington, DC')
    assert_equal 'Washington', result[:city_part]
    assert_equal 'District of Columbia', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal '7013962', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('Roxbury (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal '7015002', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('Roxbury, Mass.')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal '7015002', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('Vietnam')
    assert_equal nil, result[:city_part]
    assert_equal nil, result[:state_part]
    assert_equal 'Vietnam', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '1000145', result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo.parse('Soviet Union')
    assert_equal nil, result[:city_part]
    assert_equal nil, result[:state_part]
    assert_equal nil, result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal nil, result[:tgn_id]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    #FIXME: Should eventually still return Fenway even if not a TGN neighborhood... rewrite pending.
    result = Bplgeo.parse('Fenway (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '7013445', result[:tgn_id]
    assert_equal 'TODO: Not Implemented for Google Results', result[:street_part]
    assert_equal true, result[:term_differs_from_tgn]



  end
end
