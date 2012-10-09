require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/assessor/assessor')) 

class Test_TaxonifiAccessor < Test::Unit::TestCase

  def setup
    @headers = ["family", "genus", "subgenus", "species", "subspecies", "variety", "author", "year"]
    @csv_string = CSV.generate() do |csv|
      csv <<  @headers
      csv << ["Fooidae"]                                                                     # 0
      csv << ["Fooidae", "Blorf"]                                                            # 1  
      csv << ["Fooidae", "Blorf", "Bliff"]                                                   # 2  
      csv << ["Fooidae", "Foo",    nil,     "bar",   nil,      nil,      "Smith",  "1854"]   # 3
      csv << ["Fooidae", "Bar",    nil,     "bar",   "subbar", nil,      "Smith",  "1854"]   # 4
      csv << ["Fooidae", "Bar",    nil,     "bar",   nil,      "varbar", "Smith",  "1854"]   # 5
    end

    @csv = CSV.parse(@csv_string, {headers: true, header_converters: :downcase})
  end

  def test_first_available
    assert_equal [:family, 'Fooidae'], Taxonifi::Assessor::RowAssessor.first_available(@csv[3], [:family, :genus])
  end

  def test_last_available
    assert_equal [:genus, 'Bar'], Taxonifi::Assessor::RowAssessor.last_available(@csv[5], [:family, :genus])
  end

  def test_lump_name_rank
    assert_equal :family, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[0])
    assert_equal :genus, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[1])
    assert_equal :subgenus, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[2])
    assert_equal :species, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[3])
    assert_equal :subspecies, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[4])
    assert_equal :variety, Taxonifi::Assessor::RowAssessor.lump_name_rank(@csv[5])
  end

  # DEPRECATED
  # def test_lump_rank_parent
  #   assert_equal [nil, nil ], Taxonifi::Assessor::RowAssessor.parent_taxon_column(@csv.first)
  #   assert_equal ["family", "Fooidae"], Taxonifi::Assessor::RowAssessor.parent_taxon_column(@csv.first)
  # end

  def test_intersecting_lumps_with_data
      headers = ["authors"]
      csv_string = CSV.generate() do |csv|
        csv <<  headers
        csv << ["Smith J. and Barnes S."]
      end
     csv = CSV.parse(csv_string, {headers: true})
     assert_equal [:citation_basic, :citation_small],  Taxonifi::Assessor::RowAssessor.intersecting_lumps_with_data(csv.first)
  end 

  def test_lumps_with_data
      headers = Taxonifi::Lumper::LUMPS[:citation_small]
      csv_string = CSV.generate() do |csv|
        csv <<  headers
        csv << ["Smith J. and Barnes S.", 1912, "Foo", "Bar", "3(4)", "1-2"]
      end

     csv = CSV.parse(csv_string, {headers: true})

     assert_equal [:citation_small],  Taxonifi::Assessor::RowAssessor.lumps_with_data(csv.first)
  end

end 

