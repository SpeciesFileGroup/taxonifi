require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestTaxonifi < Test::Unit::TestCase

  def test_constants
    assert Taxonifi::RANKS
  end


end
