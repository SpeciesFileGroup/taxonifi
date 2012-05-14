module Taxonifi::Splitter::Builder

    # Load all builders (= models)
    #  TODO: perhaps use a different scope that doesn't require loading all at once
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "../models/*.rb") )) do |file|
      require file
    end

    def self.build_author_year(text)
      lexer = Taxonifi::Splitter::Lexer.new(text)
      builder = Taxonifi::Model::AuthorYear.new
      Taxonifi::Splitter::Parser.new(lexer, builder).parse_author_year
      builder
    end

    def self.build_species_name(text)
      lexer = Taxonifi::Splitter::Lexer.new(text, :species_name)
      builder = Taxonifi::Model::SpeciesName.new
      Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
      builder
    end

end
