require 'test_helper'

class TownLookupTest < ActiveSupport::TestCase
  def test_MA_lookup
    result = Bplgeo::TownLookup.state_town_lookup('MA', "This test was written in Boston, MA.")
    assert_equal '7013445', result

    result = Bplgeo::TownLookup.state_town_lookup('MA', "This test was written in East Boston, MA.")
    assert_equal '7015009', result
  end
end