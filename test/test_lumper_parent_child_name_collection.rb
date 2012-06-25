require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class Test_TaxonifiLumperParentChildNameCollection < Test::Unit::TestCase

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

  def create_a_collection
    @nc = Taxonifi::Lumper::Lumps::ParentChildNameCollection.name_collection(@csv)
  end

  def test_that_name_collection_returns_a_name_collection
    create_a_collection
    assert_equal Taxonifi::Model::NameCollection, @nc.class
  end

  def test_that_higher_taxon_names_are_created
    create_a_collection
    assert_equal "Aidae", @nc.names_at_rank('family').first.name
    assert_equal "family",  @nc.names_at_rank('family').first.rank
    assert_equal "Foo",     @nc.names_at_rank('genus').first.name
    assert @nc.names_at_rank("species").collect{|n| n.name}.include?("bar") 
    assert_equal 1, @nc.names_at_rank("genus").size 
    assert @nc.names_at_rank("subspecies").collect{|n| n.name}.include?("stuff") 
    assert @nc.names_at_rank("subspecies").collect{|n| n.name}.include?("blorf") 
  end

  def test_that_synonyms_are_properly_recognized_and_set
    csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv <<    [0,  nil, 'Root','class',nil]
      csv <<    [1,  0,   'Lygaeidae','family',nil]
      csv <<    [2,  1,   'Lygaeus','genus', nil]
      csv <<    [3,  1,   'Neortholomus','genus',nil]
      csv <<    [4,  3,   'Neortholomus scolopax (Say, 1832)','species','Lygaeus scolopax Say, 1832']
      csv <<    [5,  3,   'Neortholomus foo (Say, 1832)','species']
      csv <<    [6,  3,   'Neortholomus bar (Say, 1832)','species']
      csv <<    [7,  6,   'Neortholomus bar bar (Say, 1832)', nil]
      csv <<    [8,  3,   'Neortholomus aus (Say, 1832)','species']
      csv <<    [9,  8,   'Neortholomus aus bus (Say, 1832)', nil]
    # not yet observed
    # csv <<    [7,  3,   'Neortholomus (Neortholomus) blorf (Say, 1832)','species'] 
    # csv <<    [8,  3,   'Neortholomus (Neortholomus) blorf (Say, 1832)','species']
    end
    csv = CSV.parse(csv_string, {headers: true})

    nc = Taxonifi::Lumper::Lumps::ParentChildNameCollection.name_collection(csv)
   
    # These are the names to instantiate when we assume nominotypical names are identical, a combination is added when names 
    # are used in other combinations
    assert_equal ["Root", "Lygaeidae", "Lygaeus", "Neortholomus", "Neortholomus scolopax (Say, 1832)", "Neortholomus foo (Say, 1832)", "Neortholomus bar (Say, 1832)", "Neortholomus aus (Say, 1832)", "Neortholomus aus bus (Say, 1832)"  ], nc.name_string_array
    assert_equal 9, nc.collection.size 
    
    assert_equal 'bus Say, 1832', nc.collection.last.name_author_year_string
    
    assert_equal 2, nc.combinations.size

    # These tests a little too dependent on array order (word of warning), which is meaningless
    assert_equal 'Lygaeus', nc.combinations.last.first.name
    assert_equal [3, nil, 5, nil], nc.combinations.last.collect{|n| n.nil? ? nil : n.id } # ids start at 1 by default

    assert_equal 'Neortholomus', nc.combinations[0].first.name
    assert_equal [4, nil, 7,7], nc.combinations[0].collect{|n| n.nil? ? nil : n.id } # ids start at 1 by default

    # when author/year the same ignore?!
    # examine tblTaxonHIstory?  ... the name *is* present but the taxon history won't be.

    foo = 1

  end

end 

