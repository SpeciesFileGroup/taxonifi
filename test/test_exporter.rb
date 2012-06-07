require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/export/export')) 

class Test_TaxonifiExports < Test::Unit::TestCase

  def test_that_new_generic_export_can_be_instantiated
    assert Taxonifi::Export::Base.new
  end

  def dont_test_that_species_file_export_does_stuff
    csv = generic_csv_with_names
    nc = Taxonifi::Lumper::Lumps::EolNameCollection.name_collection(csv)
    e = Taxonifi::Export::SpeciesFile.new(:nc => nc, :authorized_user_id => 15)
    assert foo = e.export
  end 

  def test_big_file
    file = File.expand_path(File.join(File.dirname(__FILE__), 'file_fixtures/Lygaeoidea.csv'))

    csv = CSV.read(file, { 
      headers: true,
      col_sep: ",",
      header_converters: :downcase
    } ) 

    nc = Taxonifi::Lumper::Lumps::ParentChildNameCollection.name_collection(csv)
    e = Taxonifi::Export::SpeciesFile.new(:nc => nc, :authorized_user_id => 15)
    assert foo = e.export
  end

end 

