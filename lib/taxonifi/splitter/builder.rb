# Builder functionality for parsing/lexing framework. 
module Taxonifi::Splitter::Builder

  # Load all builders (= models)
  #  TODO: perhaps use a different scope that doesn't require loading all at once
  require_rel '../model'

  # Build and return Taxonifi::Model::AuthorYear from a string.
  def self.build_author_year(text)
    lexer = Taxonifi::Splitter::Lexer.new(text)
    builder = Taxonifi::Model::AuthorYear.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_author_year
    builder
  end

  # Build and return Taxonifi::Model::SpeciesName from a string.
  def self.build_species_name(text)
    lexer = Taxonifi::Splitter::Lexer.new(text, :species_name)
    builder = Taxonifi::Model::SpeciesName.new
    Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
    builder
  end

end
