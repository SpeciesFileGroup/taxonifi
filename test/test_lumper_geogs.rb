require 'helper'

class Test_TaxonifiLumperGeogs < Test::Unit::TestCase

  def setup
    @headers = ["country", "state", "county"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Canada", "", nil]
      csv << ["Canada", "Saskatchewan", nil]
      csv << ["USA", "Texas", nil]
      csv << ["USA", "Texas", "Brazos"]
      csv << ["Utopia", nil, "Wonderland"]
    end

    # The row_index looks like this:
    # 0
    # 0 1
    # 2 3 
    # 2 3 4 
    # 5 6  
    #
    # The name_index looks like
    # {:country => {"Canada" => 0, "USA" => 2, "Utopia" => 5} ... etc.

    @csv = CSV.parse(@csv_string, headers: true)
  end

  def _create_a_collection
    @gc = Taxonifi::Lumper.create_geog_collection(@csv)
  end

  def test_available_lumps
     assert_equal [:basic_geog], Taxonifi::Lumper.available_lumps(@csv.headers)
  end

    def test_that_create_geog_collection_creates_a_geog_collection
    gc = Taxonifi::Lumper.create_geog_collection(@csv)
    assert_equal Taxonifi::Model::GeogCollection, gc.class
  end

  def test_that_create_geog_collection_instantiates_geogs
    _create_a_collection 
    assert_equal 7, @gc.collection.size
    assert_equal "Canada", @gc.collection.first.name
    assert_equal "Wonderland", @gc.collection.last.name
  end

  def test_that_create_geog_collection_assigns_parenthood
    _create_a_collection 
    assert_equal 0, @gc.collection[1].parent.id
    assert_equal 5, @gc.collection[6].parent.id
    assert_equal 3, @gc.collection[4].parent.id
  end

end 

