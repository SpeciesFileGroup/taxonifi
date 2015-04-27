require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
# require File.expand_path(File.join(File.dirname(__FILE__), '../lib/export/export')) 

class Test_ExportProlog < Test::Unit::TestCase

  def test_that_prolog_export_does_stuff
    e = Taxonifi::Export::Prolog.new(:nc => names, :namespace => 'YYZ')
    assert foo = e.export
  end 


end 


