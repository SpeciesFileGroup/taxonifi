require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/name_collection')) 

class TestTaxonifiNameCollection < Test::Unit::TestCase

  def test_that_add_names_adds_names
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    assert c.add_name(n)
    assert_equal(1, c.names.size)
  end

  def test_that_name_collections_have_names
    c = Taxonifi::Model::NameCollection.new
    assert c.respond_to?(:names)
    assert_equal([], c.names)
  end

  def test_that_name_collection_returns_encompassing_rank
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    c.add_name(n)
    assert_equal 'subgenus', c.encompassing_rank 
  end

  def test_names_at_rank_returns_names
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    c.add_name(n)

    n1 = Taxonifi::Model::Name.new
    n1.rank = 'species'  
    c.add_name(n1)
 
    assert_equal 2, c.names_at_rank('species').size 
  end

end

