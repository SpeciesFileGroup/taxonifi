require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/ref_collection')) 

class TestTaxonifiRefCollection < Test::Unit::TestCase

  def test_that_add_refs_adds_refs
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert c.add_ref(n)
    assert_equal(1, c.refs.size)
  end

  def test_that_ref_collections_have_refs
    c = Taxonifi::Model::RefCollection.new
    assert c.respond_to?(:refs)
    assert_equal([], c.refs)
  end

  def test_that_add_refs_tests_for_existing_ref_id_and_raises
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    n.id = 1 
    assert_raise Taxonifi::RefCollectionError do
      c.add_ref(n)
    end
  end
  
  def test_that_current_free_id_is_incremented
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert_equal 0, c.current_free_id
    c.add_ref(n)
    assert_equal 1, c.current_free_id
  end

  def test_that_by_id_index_is_built
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert_equal 0, c.current_free_id
    c.add_ref(n)
    assert_equal ({0 => n}), c.by_id_index
  end

  def test_that_object_by_id_returns
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    id = c.add_ref(n)
    assert_equal id, c.object_by_id(id).id
  end



end

