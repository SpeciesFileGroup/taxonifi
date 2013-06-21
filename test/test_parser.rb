require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '../lib/splitter/parser')) 

class Test_TaxonifiSplitterParser < Test::Unit::TestCase
  # TODO: this could also go to builder related tests

  def test_that_parse_species_name_parses
    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff Smith, 1912", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "stuff", builder.species.name
    assert_equal "Smith", builder.names.last.author
    assert_equal 1912 ,  builder.names.last.year
    assert_equal false, builder.names.last.parens
    assert_equal "Foo stuff Smith, 1912", builder.display_name 
  end

  def test_that_parse_species_name_parses_subspecies
    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff things Smith, 1912", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "stuff", builder.species.name
    assert_equal "things", builder.subspecies.name
    assert_equal "Smith", builder.names.last.author
    assert_equal 1912 ,  builder.names.last.year
    assert_equal false, builder.names.last.parens
    assert_equal "Foo stuff things Smith, 1912", builder.display_name 
  end

  def test_that_parse_species_name_parses_subgenera
    lexer = Taxonifi::Splitter::Lexer.new("Foo (Bar) stuff things (Smith, 1912)", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "Bar", builder.subgenus.name
    assert_equal builder.genus, builder.subgenus.parent 
    assert_equal "stuff", builder.species.name
    assert_equal builder.subgenus, builder.species.parent 
    assert_equal "things", builder.subspecies.name
    assert_equal builder.species, builder.subspecies.parent 
    assert_equal "Smith", builder.names.last.author
    assert_equal 1912, builder.names.last.year
    assert_equal true, builder.names.last.parens
    assert_equal "Foo (Bar) stuff things (Smith, 1912)", builder.display_name 
  end

  def test_that_parse_species_name_parses_variety_following_subspecies
    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff things var. blorf Smith, 1912", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "stuff", builder.species.name
    assert_equal "things", builder.subspecies.name
    assert_equal "blorf", builder.variety.name
    assert_equal "Smith", builder.names.last.author
    assert_equal 1912 ,  builder.names.last.year
    assert_equal false, builder.names.last.parens
    assert_equal "Foo stuff things var. blorf Smith, 1912", builder.display_name 
  end


  def test_that_parse_species_name_parses_variety_following_species
    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff v. blorf Smith, 1912", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "stuff", builder.species.name
    assert_equal nil, builder.subspecies
    assert_equal "blorf", builder.variety.name
    assert_equal "Smith", builder.names.last.author
    assert_equal 1912 ,  builder.names.last.year
    assert_equal false, builder.names.last.parens
    assert_equal "Foo stuff var. blorf Smith, 1912", builder.display_name 
  end

  
  def test_that_parse_species_name_parses_variety_following_species_without_author_year
    lexer = Taxonifi::Splitter::Lexer.new("Foo stuff v. blorf", :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    assert_equal "Foo", builder.genus.name
    assert_equal "stuff", builder.species.name
    assert_equal nil, builder.subspecies
    assert_equal "blorf", builder.variety.name
    assert_equal nil, builder.names.last.parens # not set
    assert_equal "Foo stuff var. blorf", builder.display_name 
  end



end 

