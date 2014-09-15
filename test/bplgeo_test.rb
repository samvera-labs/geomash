require 'test_helper'

class BplgeoTest < ActiveSupport::TestCase

  def test_parse
    result = Bplgeo.parse('Boston, MA')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7013445', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal '4930956', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('New York, NY')
    assert_equal 'New York', result[:city_part]
    assert_equal 'New York', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7007567', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal '5128638', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Washington, DC')
    assert_equal 'Washington', result[:city_part]
    assert_equal 'District of Columbia', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7013962', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal '4140963', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Roxbury (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Roxbury, Mass.')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Vietnam')
    assert_equal nil, result[:city_part]
    assert_equal nil, result[:state_part]
    assert_equal 'Vietnam', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '1000145', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal nil, result[:street_part]
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'

    result = Bplgeo.parse('Soviet Union')
    assert_equal nil, result[:city_part]
    assert_equal nil, result[:state_part]
    assert_equal nil, result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal nil, result[:tgn]
    assert_equal nil, result[:street_part]

    result = Bplgeo.parse('Fenway (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Fenway/Kenmore', result[:neighborhood_part]
    assert_equal '7013445', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal nil, result[:street_part]
    assert_equal true, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'

    #Should find the Michigan Atlanta over the Georgia Atlanta
    #State part from an API giving me Atlanta????
    result = Bplgeo.parse('Atlanta, MI')
    assert_equal 'Atlanta', result[:city_part]
    assert_equal 'Michigan', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '2051159', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == 'true'
    assert_equal '4984500', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'



  end
end
