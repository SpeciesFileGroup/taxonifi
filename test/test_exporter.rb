require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/export/exporter')) 

class Test_TaxonifiExports < Test::Unit::TestCase

  def test_that_new_generic_export_can_be_instantiated
    assert Taxonifi::Export::Base.new
  end

  def test_that_new_specific_export_can_be_instantiated
    assert Taxonifi::Export::SpeciesFile.new
  end

  def dont_test_that_species_file_export_does_stuff
    csv = generic_csv_with_names
    nc = Taxonifi::Lumper::Lumps::EolNameCollection.name_collection(@csv)
    e = Taxonifi::Export::SpeciesFile.new(:nc => nc)
    assert foo = e.export
    puts "\n"
    puts foo
  end 

  def test_big_file
    file = File.expand_path(File.join(File.dirname(__FILE__), 'file_fixtures/Lygaeoidea-csv.tsv'))

    csv = CSV.read(file, { 
      headers: true,
      col_sep: "\t",
      header_converters: :downcase
    } ) 

    nc = Taxonifi::Lumper::Lumps::EolNameCollection.name_collection(csv)
    e = Taxonifi::Export::SpeciesFile.new(:nc => nc)
    assert foo = e.export
    puts "\n"
    puts foo

    debugger
    foo = 1


  end

end 

