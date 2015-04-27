require 'helper'

class Test_ExportProlog < Test::Unit::TestCase

  def test_that_prolog_export_does_stuff
    e = Taxonifi::Export::Prolog.new(:nc => names, :namespace => 'YYZ')
    assert foo = e.export
  end 

end 


