require 'test_helper'

class GeonamesTest < ActiveSupport::TestCase
  def test_geonames_lookup_from_id
    if Geomash::Geonames.geonames_username != '<username>'
      result = Geomash::Geonames.get_geonames_data('4984500')

      assert_equal '45.00473', result[:coords][:latitude]
      assert_equal '-84.14389', result[:coords][:longitude]
      assert_equal '45.00473,-84.14389', result[:coords][:combined]
      assert_equal '-84.18404', result[:coords][:box][:west]
      assert_equal '45.01697', result[:coords][:box][:north]
      assert_equal '-84.11884', result[:coords][:box][:east]
      assert_equal '44.9886', result[:coords][:box][:south]
      assert_equal 'Atlanta', result[:hier_geo][:ppla2]
      assert_equal 'Montmorency County', result[:hier_geo][:adm2]
      assert_equal 'Michigan', result[:hier_geo][:adm1]
      assert_equal 'United States', result[:hier_geo][:pcli]
      assert_equal 'North America', result[:hier_geo][:cont]
      assert_equal 'Earth', result[:hier_geo][:area]

    end
  end
end
