require 'helper'

class Test_TaxonifiExportOboNomenclature < Test::Unit::TestCase

  def test_that_obo_nomenlature_export_does_stuff
    e = Taxonifi::Export::OboNomenclature.new(:nc => names, :namespace => 'YYZ')
    assert foo = e.export
  end 


end 


