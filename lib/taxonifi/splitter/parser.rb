#
# Parser pattern taken from OboParser and other mjy gems.  
#
# The parser takes a builder and a lexer and does the actual breakdown.
#
class Taxonifi::Splitter::Parser
  def initialize(lexer, builder )
    @lexer = lexer
    @builder = builder
  end

  # parse out an author year combination. 
  # TODO: This is only indirectly tested in lumper code
  def parse_author_year
    t = @lexer.pop(Taxonifi::Splitter::Tokens::AuthorYear)

    lexer = Taxonifi::Splitter::Lexer.new(t.authors)
    authors = lexer.pop(Taxonifi::Splitter::Tokens::Authors)

    # TODO: A people collection?
    authors.names.each do |a|
      n = Taxonifi::Model::Person.new()
      n.last_name = a[:last_name]
      n.initials = a[:initials]
      @builder.people.push n 
    end

    @builder.year = t.year
    @builder.parens = t.parens
  end

  # Parse a species name 
  def parse_species_name
    t = @lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
    ranks = %w{genus subgenus species subspecies}
    names = {} 
    ranks.each do |r|
      names.merge!(r: nil)
      @builder.send("#{r}=", Taxonifi::Model::Name.new(:name => t.send(r), rank: r) ) if t.send(r)
    end

    if @lexer.peek(Taxonifi::Splitter::Tokens::Variety)
      t = @lexer.pop(Taxonifi::Splitter::Tokens::Variety)
      @builder.variety = Taxonifi::Model::Name.new(:name => t.variety, rank: 'variety')  
    end

    if @lexer.peek(Taxonifi::Splitter::Tokens::AuthorYear)
      t = @lexer.pop(Taxonifi::Splitter::Tokens::AuthorYear)
      @builder.names.last.author = t.authors
      @builder.names.last.year = t.year
      @builder.names.last.parens = t.parens
      @builder.names.last.derive_authors_year
    end
  
    @builder
  end

end
