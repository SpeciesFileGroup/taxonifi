require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/models/name_collection')) 

class TestTaxonifiNameCollection < Test::Unit::TestCase

  def test_that_add_objects_adds_to_collection
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    assert c.add_object(n)
    assert_equal(1, c.collection.size)
  end

  def test_that_name_collections_have_collections
    c = Taxonifi::Model::NameCollection.new
    assert c.respond_to?(:collection)
    assert_equal([], c.collection)
  end

  def test_that_name_collection_returns_encompassing_rank
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    c.add_object(n)
    assert_equal 'subgenus', c.encompassing_rank 
  end

  def test_names_at_rank_returns_names
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    c.add_object(n)

    n1 = Taxonifi::Model::Name.new
    n1.rank = 'species'  
    c.add_object(n1)

    assert_equal 2, c.names_at_rank('species').size 
  end

  def test_that_add_objects_tests_for_existing_name_id_and_raises
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    n.id = 1 
    assert_raise Taxonifi::CollectionError do
      c.add_object(n)
    end
  end

  def test_that_current_free_id_is_incremented
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    assert_equal 0, c.current_free_id
    c.add_object(n)
    assert_equal 1, c.current_free_id
  end

  def test_that_by_id_index_is_built
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    assert_equal 0, c.current_free_id
    c.add_object(n)
    assert_equal ({0 => n}), c.by_id_index
  end

  def test_that_object_by_id_returns
    c = Taxonifi::Model::NameCollection.new
    n = Taxonifi::Model::Name.new
    n.rank = 'species'  
    id = c.add_object(n).id
    assert_equal id, c.object_by_id(id).id
  end

  def test_that_parent_id_vector_returns_a_id_vector
    c = Taxonifi::Model::NameCollection.new

    n1 = Taxonifi::Model::Name.new(:name => "Fooidae", :rank => "family")
    n2 = Taxonifi::Model::Name.new(:name => "Bar",     :rank => "genus")
    n3 = Taxonifi::Model::Name.new(:name => "blorf",   :rank => "species")

    assert_equal "family",  n1.rank
    assert_equal "genus",   n2.rank
    assert_equal "species", n3.rank

    c.add_object(n1)
    c.add_object(n2)
    c.add_object(n3)

    assert_equal 0, n1.id
    assert_equal 1, n2.id
    assert_equal 2, n3.id


    n3.parent = n2
    n2.parent = n1

    #  c.object_by_id(2).parent = c.object_by_id(1)
    #  c.object_by_id(1).parent = c.object_by_id(0)

    assert_equal [0,1], c.parent_id_vector(2)
    assert_equal [0], c.parent_id_vector(1)
  end 

  def test_that_name_collection_indexes_by_name_as_well_as_id
    c = Taxonifi::Model::NameCollection.new
    n1 = Taxonifi::Model::Name.new(:name => "Fooidae", :rank => "family")
    c.add_object(n1) 
    assert_equal "Fooidae", c.by_name_index['family'].keys.first
  end

  def test_name_exists?
    c = Taxonifi::Model::NameCollection.new
    n1 = Taxonifi::Model::Name.new(:name => "Fooidae", :rank => "family")
    n2 = Taxonifi::Model::Name.new(:name => "Bar",     :rank => "genus", :parent => n1)
    n3 = Taxonifi::Model::Name.new(:name => "Bar",     :rank => "genus", :parent => n1)
    n4 = Taxonifi::Model::Name.new(:name => "Bar",     :rank => "subgenus", :parent => n2)
    n5 = Taxonifi::Model::Name.new(:name => "foo",     :rank => "species", :parent => n2)
    n6 = Taxonifi::Model::Name.new(:name => "foo",     :rank => "species", :parent => n2)
    c.add_object(n1) 
    c.add_object(n2) 
    c.add_object(n5) 
    assert c.name_exists?(n3), "Name exists, but not caught."
    assert c.name_exists?(n6), "Name exists, but not caught."
    assert !c.name_exists?(n4), "Name doesn't exist, but asserted to."
    assert_equal n2.id, c.name_exists?(n3) 
  end

  def test_that_name_collection_generate_ref_collection
    c = Taxonifi::Model::NameCollection.new
    c.generate_ref_collection
    assert rc = c.ref_collection
    assert_equal Taxonifi::Model::RefCollection,  rc.class
  end 

  def test_that_name_collection_populates_ref_collection
    c = Taxonifi::Model::NameCollection.new
    n1 = Taxonifi::Model::Name.new(:name => "Fooidae", :rank => "family", :author => "Smith and Jones", :year => 2002)
    n2 = Taxonifi::Model::Name.new(:name => "Bar",     :rank => "genus", :parent => n1)
    n3 = Taxonifi::Model::Name.new(:name => "foo",     :rank => "species", :parent => n2, :author => "Smith, Jones and Simon", :year => 2012)
    n4 = Taxonifi::Model::Name.new(:name => "bar",     :rank => "species", :parent => n2, :author => "Jones", :year => 2011)
    n5 = Taxonifi::Model::Name.new(:name => "blorf",   :rank => "species", :parent => n2, :author => "Jones", :year => 2011)

    [n1,n2,n3,n4].each do |n| 
      c.add_object(n) 
    end

    c.generate_ref_collection
    assert_equal 3, c.ref_collection.collection.size 
    # References are sorted 
    assert_equal ['Jones'], c.ref_collection.collection.first.authors.collect{|r| r.last_name} 
    assert_equal ['Smith', 'Jones'], c.ref_collection.collection[1].authors.collect{|r| r.last_name} 
    assert_equal ['Smith', 'Jones', 'Simon'], c.ref_collection.collection.last.authors.collect{|r| r.last_name}
    assert_equal 2011, c.ref_collection.collection.first.year
    foo = 1
  end

end

