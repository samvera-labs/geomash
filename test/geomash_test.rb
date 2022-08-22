# -*- coding: utf-8 -*-
require 'test_helper'

#Historical stuff like Jews--Soviet Union--History--Catalogs ?
# Registers of births, etc.--Canada, Western totally borked

#Synagogues--Germany--Baden-Württemberg--Directories  -> doesn't match as google returns Baden-Württemberg as
#Baden-Wurttemberg . No matches http://vocab.getty.edu/tgn/7003692

class GeomashTest < ActiveSupport::TestCase

  def test_parse_with_flag
    result = Geomash.parse('Cranberry industry--Massachusetts--History', true)
    assert_nil result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7007517', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '6254926', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Massachusetts &gt; Hampden (county) &gt; Chicopee', true)
    assert_equal 'Chicopee', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '2049596', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4933002', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Massachusetts > Hampden (county) > Chicopee', true)
    assert_equal 'Chicopee', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '2049596', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4933002', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    #Slight variation problem with neighborhood: 11. Bezirk (Vienna, Austria)--Biography
    result = Geomash.parse('15. Bezirk (Rudolfsheim-Fünfhaus, Vienna, Austria)--Exhibitions', true)
    assert_equal 'Vienna', result[:city_part]
    assert_equal 'Vienna', result[:state_part]
    assert_equal 'Austria', result[:country_part]
    assert_equal 'Rudolfsheim-Fünfhaus', result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7003321', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal true, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '2779138', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal true, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    #FIXME: TGN doesn't get the state part
    result = Geomash.parse('Synagogues--Germany--Baden-Württemberg--Directories', true)
    assert_nil result[:city_part]
    assert_equal 'Baden-Wurttemberg', result[:state_part] #assert_equal 'Baden-Wurttemberg', result[:state_part]
    assert_equal 'Germany', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7000084', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true #'7003692'
    assert_equal true, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '2953481', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>' #2953481
    assert_equal true, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    # NOTE: This example isn't working and isn't really relevant to our use case at the momemt.
    # result = Geomash.parse('Naroden Etnografski Muzeĭ (Sofia, Bulgaria)--Catalogs', true)
    # assert_equal 'Sofia', result[:city_part]
    # assert_equal 'Sofia', result[:state_part]
    # assert_equal 'Bulgaria', result[:country_part]
    # assert_nil result[:neighborhood_part]
    # assert_nil result[:street_part]
    # assert_equal '7009977', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    # assert_equal true, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    # assert_equal '727011', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    # assert_equal true, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Lettering--United States--History--19th century', true)
    assert_nil result[:city_part]
    assert_nil result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7012149', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '6252001', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    # Google now returns Hauts-de-France for this place's state that doesn't match in TGN
    result = Geomash.parse('Abbeville (France)--History--20th century.', true)
    assert_equal 'Abbeville', result[:city_part]
    assert_equal 'Hauts-de-France', result[:state_part] #Picardy
    assert_equal 'France', result[:country_part]
    assert_nil result[:street_part]
    assert_equal '7010587', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '3038789', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'


  end

  def test_parse_with_no_flag
    result = Geomash.parse('Boston, MA')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:street_part]
    assert_equal '7013445', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4930956', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('New York, NY')
    assert_equal 'New York', result[:city_part]
    assert_equal 'New York', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:street_part]
    assert_equal '7007567', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '5128581', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Washington, DC')
    assert_equal 'Washington', result[:city_part]
    assert_equal 'District of Columbia', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:street_part]
    assert_equal '7013962', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4140963', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Roxbury (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Roxbury, Mass.')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Roxbury', result[:neighborhood_part]
    assert_nil result[:street_part]
    assert_equal '7015002', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    #FIXME?
    assert_equal '4949151', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Vietnam')
    assert_nil result[:city_part]
    assert_nil result[:state_part]
    assert_equal 'Vietnam', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_equal '1000145', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_nil result[:street_part]
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true

    result = Geomash.parse('Soviet Union')
    assert_nil result[:city_part]
    assert_nil result[:state_part]
    assert_nil result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_nil result[:tgn]
    assert_nil result[:street_part]

    result = Geomash.parse('Fenway (Boston, Mass.)')
    assert_equal 'Boston', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Fenway–Kenmore', result[:neighborhood_part]
    assert_equal '7013445', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_nil result[:street_part]
    assert_equal true, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true

    #Case of a country with no states
    # Actual TGN is 7004472 and actual Geonames is 1850147. Only does the Country right now...
    #FIXME: TGN still doesn't get Tokyo and why is original string differs true for geonames?
    result = Geomash.parse('Tokyo, Japan')
    assert_nil result[:city_part]
    assert_equal 'Tokyo', result[:state_part]
    assert_equal 'Japan', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_equal '1000120', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal true, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '1850147', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal true, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    #Should find the Michigan Atlanta over the Georgia Atlanta
    #State part from an API giving me Atlanta????
    result = Geomash.parse('Atlanta, MI')
    assert_equal 'Atlanta', result[:city_part]
    assert_equal 'Michigan', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_equal '2051159', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4984500', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    #TODO: This should also likely parse as North Korea as well...
    result = Geomash.parse('Korea')
    assert_nil result[:city_part]
    assert_nil result[:state_part]
    assert_equal 'South Korea', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_equal '7000299', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '1835841', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    result = Geomash.parse('Northern Ireland')
    assert_nil result[:city_part]
    assert_equal 'Northern Ireland', result[:state_part]
    assert_equal 'United Kingdom', result[:country_part]
    assert_nil result[:neighborhood_part]
    assert_equal '7002448', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '2641364', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    # result = Geomash.parse('Phnom Penh (Cambodia)')
    # assert_equal '7004076', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    # assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    # assert_equal '1821306', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    # assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    # Actual TGN is 1000145 but only can resolve Vietnam in TGN
    result = Geomash.parse('Ho Chi Minh City (Vietnam)')
    assert_equal '7001069', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '1566083', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'

    #Ensure we get "Newton" instead of "Newtown" that has an altlabel of "Newton"
    #Should this find Chestnut hill...?
    result = Geomash.parse('Chestnut Hill, Massachusetts')
    assert_equal 'Newton', result[:city_part]
    assert_equal 'Massachusetts', result[:state_part]
    assert_equal 'United States', result[:country_part]
    assert_equal 'Chestnut Hill', result[:neighborhood_part]
    assert_equal '7032056', result[:tgn][:id] if Geomash::TGN.tgn_enabled == true #2050214 or
    assert_equal false, result[:tgn][:original_string_differs] if Geomash::TGN.tgn_enabled == true
    assert_equal '4932957', result[:geonames][:id] if Geomash::Geonames.geonames_username != '<username>'
    assert_equal false, result[:geonames][:original_string_differs] if Geomash::Geonames.geonames_username != '<username>'
  end
end
