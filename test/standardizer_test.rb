require 'test_helper'

class ParserTest < ActiveSupport::TestCase
  def test_dedup_geo
    sample_array = ['Saigon, Vietnam', 'Saigon (Vietnam)', 'Vietnam', 'Vietnam, Party']
    result = Bplgeo::Standardizer.dedup_geo(sample_array)
    assert_equal ['Saigon, Vietnam', 'Vietnam', 'Vietnam, Party'], result

    result = Bplgeo::Standardizer.dedup_geo(sample_array, true)
    assert_equal ['Saigon, Vietnam', 'Vietnam, Party'], result

    sample_array << 'Some Place, Vietnam'
    result = Bplgeo::Standardizer.dedup_geo(sample_array)
    assert_equal ['Saigon, Vietnam', 'Vietnam', 'Vietnam, Party', 'Some Place, Vietnam'], result

    result = Bplgeo::Standardizer.dedup_geo(sample_array, true)
    assert_equal ['Saigon, Vietnam', 'Vietnam, Party', 'Some Place, Vietnam'], result

    #sample_array << 'Some Place, Vietnam, Saigon'
    #result = Bplgeo::Standardizer.dedup_geo(sample_array, true)
    #assert_equal ['Some Place, Vietnam, Saigon'], result

  end


end