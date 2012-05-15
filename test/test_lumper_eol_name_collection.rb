require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

# Builder construction

class Test_TaxonifiLumperEolNameCollection < Test::Unit::TestCase

  def setup
    @headers = %W{identifier parent child rank synonyms}
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << [0, nil, "Root", "class", nil ]
      csv << [1, "0", "Aidae", "Family", nil ]
      csv << [2, "1", "Foo", "Genus", nil ]
      csv << [3, "2", "Foo bar", "species", nil ]                                          # case testing
      csv << [4, "2", "Foo bar stuff (Guy, 1921)", "species", "Foo bar blorf (Guy, 1921)"] # initial subspecies rank data had rank blank, assuming they will be called species
      csv << [5, "0", "Bidae", "Family", nil ]
     
    end

    @csv = CSV.parse(@csv_string, {headers: true})
  end

  def _create_a_collection
    @nc = Taxonifi::Lumper::Lumps::EolNameCollection.name_collection(@csv)
  end

  def test_that_name_collection_returns_a_name_collection
    _create_a_collection
    assert_equal Taxonifi::Model::NameCollection, @nc.class
  end

  def test_that_higher_taxon_names_are_created
    _create_a_collection
    assert_equal "Aidae", @nc.names_at_rank('family').first.name
    assert_equal "family",  @nc.names_at_rank('family').first.rank
    assert_equal "Foo",     @nc.names_at_rank('genus').first.name
    assert @nc.names_at_rank("species").collect{|n| n.name}.include?("bar") 
    assert_equal 1, @nc.names_at_rank("genus").size 
    assert @nc.names_at_rank("subspecies").collect{|n| n.name}.include?("stuff") 
    assert @nc.names_at_rank("subspecies").collect{|n| n.name}.include?("blorf") 
  end

end 

