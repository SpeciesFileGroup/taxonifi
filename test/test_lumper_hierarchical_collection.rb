require 'helper'

class Test_TaxonifiLumperHierarchicalCollection < Test::Unit::TestCase

  def setup
    @headers = ["a", "b", "c"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << %w{a b c}
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def test_that_create_hierarchical_collection_creates_collection
    c = Taxonifi::Lumper.create_hierarchical_collection(@csv, %w{a b c},  )
    assert_equal Taxonifi::Model::Collection, c.class
  end

  def test_that_a_hierarchical_collection_instantiates_generic_objects
    c = Taxonifi::Lumper.create_hierarchical_collection(@csv, %w{a b c})
    assert_equal Taxonifi::Model::GenericObject, c.collection.first.class
  end

  def test_that_collection_store_names
    c = Taxonifi::Lumper.create_hierarchical_collection(@csv, %w{a b c})
    assert_equal "a", c.collection.first.name
    assert_equal "b", c.collection[1].name
    assert_equal "c", c.collection[2].name
  end

  def test_that_header_order_is_applied
    c = Taxonifi::Lumper.create_hierarchical_collection(@csv, %w{c a b})
    assert_equal "c", c.collection.first.name
    assert_equal "a", c.collection[1].name
    assert_equal "b", c.collection[2].name
  end

  def test_that_parent_objects_are_assigned
    c = Taxonifi::Lumper.create_hierarchical_collection(@csv, %w{a b c})
    assert_equal nil, c.collection.first.parent
    assert_equal "a", c.collection[1].parent.name
    assert_equal "b", c.collection[2].parent.name
  end

  def test_that_parents_are_assigned_across_blank_columns
    csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["a", nil, "c"]
    end
    csv = CSV.parse(csv_string, {headers: true})
    c = Taxonifi::Lumper.create_hierarchical_collection(csv, %w{a b c})
    assert_equal nil, c.collection.first.parent
    assert_equal "a", c.collection[1].parent.name
  end

  def test_that_names_at_rank_are_synonymous_when_parents_are_identical
    csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["a", "b", "c"]
      csv << ["a", "b", "d"]
      csv << ["e", "b", "f"]
    end
    csv = CSV.parse(csv_string, {headers: true})
    c = Taxonifi::Lumper.create_hierarchical_collection(csv, %w{a b c})
    assert_equal %w{a b c d e b f}, c.collection.collect{|o| o.name}
    assert_equal 7, c.collection.size
  end

# def test_that_create_geog_collection_instantiates_geogs
#   _create_a_collection 
#   assert_equal 7, @gc.collection.size
#   assert_equal "Canada", @gc.collection.first.name
#   assert_equal "Wonderland", @gc.collection.last.name
# end

# def test_that_create_geog_collection_assigns_parenthood
#   _create_a_collection 
#   assert_equal 0, @gc.collection[1].parent.id
#   assert_equal 5, @gc.collection[6].parent.id
#   assert_equal 3, @gc.collection[4].parent.id
# end

end 

