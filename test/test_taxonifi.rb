require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/taxonifi'))

class TestTaxonifi < Test::Unit::TestCase

  def test_constants
    assert Taxonifi::RANKS
  end


end
