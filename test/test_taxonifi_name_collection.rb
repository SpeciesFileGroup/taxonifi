require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/name_collection')) 

class TestTaxonifiNameCollection < Test::Unit::TestCase

  def test_truth
    assert(true)
  end

  def test_that_name_collections_have_names
    c = Taxonifi::Model::NameCollection.new
    assert c.respond_to?(:names)
    assert_equal([], c.names)
  end

end

