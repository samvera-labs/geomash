require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def test_dedup_geo
    sample_array = ['Saigon, Vietnam', 'Saigon (Vietnam)', 'Vietnam', 'Vietnam, Party']
    result = Geomash::Standardizer.dedup_geo(sample_array)
    assert_equal ['Saigon, Vietnam', 'Vietnam', 'Vietnam, Party'], result

    result = Geomash::Standardizer.dedup_geo(sample_array, true)
    assert_equal ['Saigon, Vietnam', 'Vietnam, Party'], result

    sample_array << 'Some Place, Vietnam'
    result = Geomash::Standardizer.dedup_geo(sample_array)
    assert_equal ['Saigon, Vietnam', 'Vietnam', 'Vietnam, Party', 'Some Place, Vietnam'], result

    result = Geomash::Standardizer.dedup_geo(sample_array, true)
    assert_equal ['Saigon, Vietnam', 'Vietnam, Party', 'Some Place, Vietnam'], result

    #sample_array << 'Some Place, Vietnam, Saigon'
    #result = Geomash::Standardizer.dedup_geo(sample_array, true)
    #assert_equal ['Some Place, Vietnam, Saigon'], result

  end

  def test_geographic_parser
    #Nil results... problem cases
    result = Geomash::Standardizer.parse_for_geographic_term('Yuma Indians')
    assert_equal '', result

    result = Geomash::Standardizer.parse_for_geographic_term('Yuma Indians--Woodworking')
    assert_equal '', result

    result = Geomash::Standardizer.parse_for_geographic_term('Norway maple')
    assert_equal '', result

    result = Geomash::Standardizer.parse_for_geographic_term('Some Value--German Engineering--Cars')
    assert_equal '', result

    result = Geomash::Standardizer.parse_for_geographic_term('Art, Japanese')
    assert_equal '', result

    #Normal cases
    result = Geomash::Standardizer.parse_for_geographic_term('Palmer (Mass) - history or Stores (retail trade) - Palmer, Mass')
    assert_equal 'Palmer, Mass', result

    result = Geomash::Standardizer.parse_for_geographic_term('Naroden Etnografski Muzeĭ (Sofia, Bulgaria)--Catalogs')
    assert_equal 'Naroden Etnografski Muzeĭ, Sofia, Bulgaria', result

    result = Geomash::Standardizer.parse_for_geographic_term('Germany')
    assert_equal 'Germany', result

    result = Geomash::Standardizer.parse_for_geographic_term('United States')
    assert_equal 'United States', result

    result = Geomash::Standardizer.parse_for_geographic_term('South Korea')
    assert_equal 'South Korea', result

    result = Geomash::Standardizer.parse_for_geographic_term('Blah (North Korea)')
    assert_equal 'Blah, North Korea', result
  end


end
