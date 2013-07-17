require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/ref_collection')) 

class TestTaxonifiRefCollection < Test::Unit::TestCase

  def test_that_add_objects_adds_refs
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert c.add_object(n)
    assert_equal(1, c.collection.size)
  end

  def test_that_ref_collections_have_refs
    c = Taxonifi::Model::RefCollection.new
    assert c.respond_to?(:collection)
    assert_equal([], c.collection)
  end

  def test_that_add_objects_tests_for_existing_ref_id_and_raises
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    n.id = 1 
    assert_raise Taxonifi::CollectionError do
      c.add_object(n)
    end
  end
  
  def test_that_current_free_id_is_incremented
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert_equal 0, c.current_free_id
    c.add_object(n)
    assert_equal 1, c.current_free_id
  end

  def test_that_by_id_index_is_built
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    assert_equal 0, c.current_free_id
    c.add_object(n)
    assert_equal ({0 => n}), c.by_id_index
  end

  def test_that_object_by_id_returns
    c = Taxonifi::Model::RefCollection.new
    n = Taxonifi::Model::Ref.new
    id = c.add_object(n).id
    assert_equal id, c.object_by_id(id).id
  end

  def test_uniquify_authors
    c = Taxonifi::Model::RefCollection.new
    ['Smith, A.R. 1920', 'Jones, A.R. and Smith, A.R. 1940', 'Jones, B. 1999', 'Jones, A. R. 1922', 'Jones, A. R., Smith, A.R. and Frank, A. 1943'].each do |a|
      # smith ar
      # jones ar
      # jones b
      # frank a
      n = Taxonifi::Model::Ref.new(:author_year => a)
      c.add_object(n)
    end
   
    assert_equal 8, c.all_authors.size
    assert_not_equal c.collection.first.authors.first, c.collection[1].authors.last
    
    c.uniquify_authors(5)
    assert_equal 4, c.all_authors.size
    assert_equal c.collection.first.authors.first, c.collection[1].authors.last
    assert_equal c.collection.first.authors.first, c.collection[4].authors[1]
    assert_equal c.collection[1].authors.first, c.collection[3].authors.first
    assert_equal 5, c.collection.first.authors.first.id 
  end

  def test_uniquify_tricky_authors
    c = Taxonifi::Model::RefCollection.new
    ['Quate and Quate, 1920',].each do |a|
      n = Taxonifi::Model::Ref.new(:author_year => a)
      c.add_object(n)
    end

    assert_equal 2, c.unique_authors.size
    c.uniquify_authors(0)
    assert_equal 2, c.unique_authors.size
    assert_not_equal c.collection.first.authors.first, c.collection.first.authors.last
  end

  def test_uniquify_trickier_authors
    c = Taxonifi::Model::RefCollection.new
    ['Quate and Quate, 1920', 'Quate, Smith and Quate, 1921', 'Smith, 1930', 'Quate, Quate, and Smith, 2000'].each do |a|
      # Quate1
      # Quate2
      # Smith1
      n = Taxonifi::Model::Ref.new(:author_year => a)
      c.add_object(n)
    end

    assert_equal 9, c.all_authors.size
    c.uniquify_authors(0)
    assert_equal 3, c.unique_authors.size
    # assert_not_equal c.collection.first.authors.first, c.collection.first.authors.last
  end




end

