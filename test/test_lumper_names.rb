require 'helper'
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lumper/lumper')) 

# Builder construction

class Test_TaxonifiLumperNames < Test::Unit::TestCase

  def setup
    @headers = ["family", "genus", "species", "author", "year"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Fooidae", "Foo", "bar", "Smith", "1854"]
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def test_that_setup_setups
    assert_equal @headers, @csv.headers
  end

  def test_available_lumps_raise_without_arrays
    assert_raises Taxonifi::Lumper::LumperError do
      Taxonifi::Lumper.available_lumps( "foo" )
    end
  end

  def test_available_lumps
    assert Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::QUAD ).include?(:quadrinomial)
    assert Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::AUTHOR_YEAR + Taxonifi::Lumper::QUAD ).include?(:quad_author_year)
    assert (not Taxonifi::Lumper.available_lumps( Taxonifi::Lumper::AUTHOR_YEAR + Taxonifi::Lumper::QUAD ).include?(:names) )
  end

  def test_create_name_collection_creates_a_name_collection
    assert_equal Taxonifi::Model::NameCollection, Taxonifi::Lumper.create_name_collection(@csv).class
  end

  def test_that_create_name_collection_raises_when_fed_non_csv
    assert_raises Taxonifi::Lumper::LumperError do
      Taxonifi::Lumper.create_name_collection("FOO")
    end
  end

  def test_that_create_name_collection_populates_a_name_collection
    nc = Taxonifi::Lumper.create_name_collection(@csv)
    assert_equal 3, nc.collection.size
    assert_equal ["Fooidae", "Foo", "bar"], nc.collection.collect{|n| n.name}
  end

  def test_that_create_name_collection_parentifies
    nc = Taxonifi::Lumper.create_name_collection(@csv)
    assert_equal nc.collection[0], nc.collection[1].parent
    assert_equal nc.collection[1], nc.collection[2].parent
  end

  def test_that_create_a_name_collection_handles_homonomy
    string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Fooidae", "Foo", "bar", "Smith", "1854"]
      csv << ["Blorf",   "Foo", "bar", "Smith", "1854"]
      csv << ["Fooidae", "Bar", "bar", "Smith", "1854"]
    end

    # The index should break down like this
    # 0 2 5
    # 1 3 6
    # 0 4 7

    csv = CSV.parse(string, {headers: true})
    nc = Taxonifi::Lumper.create_name_collection(csv)

    assert_equal nc.collection[2], nc.collection[5].parent
    assert_equal nc.collection[0], nc.collection[2].parent
    assert_equal nc.collection[1], nc.collection[3].parent
    assert_equal nc.collection[3], nc.collection[6].parent
    assert_equal nc.collection[0], nc.collection[4].parent
    assert_equal nc.collection[4], nc.collection[7].parent
  end


  def test_that_create_a_name_collection_handles_author_year
    string = CSV.generate() do |csv|
      csv << %w{family genus species author_year}
      csv << ["Fooidae", "Foo", "bar", "Smith, 1854"]
      csv << ["Fooidae", "Foo", "foo", "(Smith, 1854)"]
    end
   
    # 0  Fooidae
    # 1  Foo
    # 2  bar
    # 3  foo 

    csv = CSV.parse(string, {headers: true})
    nc = Taxonifi::Lumper.create_name_collection(csv)
    assert_equal 1, nc.collection[3].author.size
    assert_equal 'Smith', nc.collection[3].author.first.last_name
    assert_equal 1854, nc.collection[3].year

    # Name only applies to the "last" name in the order.
    assert_equal nil, nc.collection[0].author
    assert_equal nil, nc.collection[1].author
    assert_equal 1, nc.collection[2].author.size

    assert_equal nil, nc.collection[0].original_combination
    assert_equal true, nc.collection[2].original_combination
    assert_equal false, nc.collection[3].original_combination
  end

#--- reference collections

end 
