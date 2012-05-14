require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/splitter/parser')) 

class Test_TaxonifiSplitterParser < Test::Unit::TestCase

  # TODO: this could also go to builder related tests
  def test_that_parse_species_name_parses
      lexer = Taxonifi::Splitter::Lexer.new("Foo (Bar) stuff things (Smith, 1912)", :species_name)
      builder = Taxonifi::Model::SpeciesName.new
      Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
      assert_equal "Foo", builder.genus.name
      assert_equal "Bar", builder.subgenus.name
      assert_equal builder.genus, builder.subgenus.parent 
require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
      assert_equal "stuff", builder.species.name
      assert_equal builder.subgenus, builder.species.parent 
      assert_equal "things", builder.subspecies.name
      assert_equal builder.species, builder.subspecies.parent 
      assert_equal "Smith", builder.names.last.author
      assert_equal "1912",  builder.names.last.year
      assert_equal true, builder.names.last.original_combination


      lexer = Taxonifi::Splitter::Lexer.new("Foo stuff things Smith, 1912", :species_name)
      builder = Taxonifi::Model::SpeciesName.new
      Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
      assert_equal "Foo", builder.genus.name
      assert_equal "stuff", builder.species.name
      assert_equal "things", builder.subspecies.name
      assert_equal "Smith", builder.names.last.author
      assert_equal "1912",  builder.names.last.year
      assert_equal false, builder.names.last.original_combination
  end


end 

