require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/base')) 

class TestTaxonifiBase < Test::Unit::TestCase

  def test_new_base
    assert b = Taxonifi::Model::Base.new() 
  end

  def test_that_base_has_an_id
    n = Taxonifi::Model::Base.new() 
    assert n.respond_to?(:id)
  end
 
  def test_that_base_has_a_row_number
    n = Taxonifi::Model::Base.new() 
    assert n.respond_to?(:row_number)
  end

  def test_identical_by_attributes
    n = Taxonifi::Model::Base.new() 
    assert n.identical?(n)
  end

end
