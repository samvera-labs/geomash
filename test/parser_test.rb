require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def test_google_parser
    result = Bplgeo::Parser.parse_google_api('Boston, MA')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]

    result = Bplgeo::Parser.parse_google_api('700 Boylston St, Boston, MA 02116')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal true, result[:term_differs_from_tgn]

    result = Bplgeo::Parser.parse_google_api('Roxbury (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal nil, result[:term_differs_from_tgn]


    #FIXME!!!  Is this alright?
    #result = Bplgeo::Parser.parse_google_api('201 Dowman Dr., Atlanta, GA 30322')
    #assert_equal 'Atlanta', result[:city_part]
    #assert_equal 'Georgia', result[:state_part]
    #assert_equal 'United States', result[:country_part]
    #assert_equal 'true', result[:term_differs_from_tgn]
  end


end