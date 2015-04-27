require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
# require File.expand_path(File.join(File.dirname(__FILE__), '../lib/lumper/clump')) 

# Builder construction

class Test_TaxonifiLumperClump < Test::Unit::TestCase

  def setup
    @headers = ["family", "genus", "species", "author", "year"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Fooidae", "Foo", "bar", "Smith", "1854"]
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def test_new_clump_without_params_can_be_created
    assert c = Taxonifi::Lumper::Clump.new
  end

  def test_new_clump_with_default_csv_can_be_created
    assert c = Taxonifi::Lumper::Clump.new(@csv)
  end

  def test_that_csv_can_be_added_to_clump_that_has_no_csv
    c = Taxonifi::Lumper::Clump.new
    assert c.add_csv(@csv)
  end

  def test_that_clump_with_csv_will_not_add_csv
    c = Taxonifi::Lumper::Clump.new
    c.add_csv(@csv)
    assert !c.add_csv(@csv)
  end

  def test_that_clump_with_csv_can_detach_csv
    c = Taxonifi::Lumper::Clump.new
    c.add_csv(@csv)
    assert c.remove_csv
  end

  def test_that_clump_without_csv_can_not_detach_csv
    c = Taxonifi::Lumper::Clump.new
    assert !c.remove_csv
  end

  def test_that_name_collection_can_be_derived_from_clump
    c = Taxonifi::Lumper::Clump.new
    c.add_csv(@csv)
    assert c.get_from_csv(:collection => :name)
    assert_equal ['collection0'], c.collections.keys
    assert_equal Taxonifi::Model::NameCollection, c.collections['collection0'].class
  end

  def test_that_ref_collection_can_be_derived_from_clump
    c = Taxonifi::Lumper::Clump.new
    c.add_csv(@csv)
    assert c.get_from_csv(:collection => :ref, :name => 'my_collection')
    assert_equal ['my_collection'], c.collections.keys
    assert_equal Taxonifi::Model::RefCollection, c.collections['my_collection'].class
  end

  def test_that_existing_named_collections_are_not_overwritten
    c = Taxonifi::Lumper::Clump.new
    c.add_csv(@csv)
    assert c.get_from_csv(:collection => :name, :name => 'my_collection')
    assert !c.get_from_csv(:collection => :name, :name => 'my_collection')
  end


  # name.ref -> 

end 

