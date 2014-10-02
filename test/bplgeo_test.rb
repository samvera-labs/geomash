require 'test_helper'

#Historical stuff like Jews--Soviet Union--History--Catalogs ?
# Registers of births, etc.--Canada, Western totally borked

#Synagogues--Germany--Baden-Württemberg--Directories  -> doesn't match as google returns Baden-Württemberg as
#Baden-Wurttemberg . No matches http://vocab.getty.edu/tgn/7003692

class BplgeoTest < ActiveSupport::TestCase

  def test_parse_with_flag
    result = Bplgeo.parse('Abbeville (France)--History--20th century.', true)
    assert_equal 'Abbeville', result[:city_part]
    assert_equal 'Picardy', result[:state_part]
    assert_equal 'France', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7010587', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal true, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '2987374', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal true, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    #Slight variation problem with neighborhood: 11. Bezirk (Vienna, Austria)--Biography
    result = Bplgeo.parse('15. Bezirk (Rudolfsheim-Fünfhaus, Vienna, Austria)--Exhibitions', true)
    assert_equal 'Vienna', result[:city_part]
    assert_equal 'Vienna', result[:state_part]
    assert_equal 'Austria', result[:country_part]
    assert_equal 'Rudolfsheim-Fünfhaus', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7003321', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal true, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '2779138', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal true, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Synagogues--Germany--Baden-Württemberg--Directories', true)
    assert_equal nil, result[:city_part]
    assert_equal 'Baden-Wurttemberg', result[:state_part]
    assert_equal 'Germany', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7003692', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal true, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '2953481', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal true, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

  end

  def test_parse_with_no_flag
    result = Bplgeo.parse('Boston, MA')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7013445', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '4930956', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('New York, NY')
    assert_equal 'New York', result[:city_part]
    assert_equal 'New York', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7007567', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '5128581', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Washington, DC')
    assert_equal 'Washington', result[:city_part]
    assert_equal 'District of Columbia', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:street_part]
    assert_equal '7013962', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '4140963', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Roxbury (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Roxbury, Mass.')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_equal nil, result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'

    result = Bplgeo.parse('Vietnam')
    assert_equal nil, result[:city_part]
    assert_equal nil, result[:state_part]
    assert_equal 'Vietnam', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '1000145', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal nil, result[:street_part]
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true

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
    assert_equal '7013445', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal nil, result[:street_part]
    assert_equal true, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true

    #Should find the Michigan Atlanta over the Georgia Atlanta
    #State part from an API giving me Atlanta????
    result = Bplgeo.parse('Atlanta, MI')
    assert_equal 'Atlanta', result[:city_part]
    assert_equal 'Michigan', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal nil, result[:neighborhood_part]
    assert_equal '2051159', result[:tgn][:id] if Bplgeo::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Bplgeo::TGN.tgn_enabled == true
    assert_equal '4984500', result[:geonames][:id] if Bplgeo::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Bplgeo::Geonames.geonames_username != '<username>'





  end
end
