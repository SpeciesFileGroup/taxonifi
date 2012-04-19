class Taxonifi::Splitter::Parser
  def initialize(lexer, builder )
    @lexer = lexer
    @builder = builder
  end

  # Each method here defines the pattern of tokens to look for.  Shared pattern matches are prefaced with underscore (_).
  def parse_author_year
    t = @lexer.pop(Taxonifi::Splitter::Tokens::AuthorYear)

    lexer = Taxonifi::Splitter::Lexer.new(t.authors)
    authors = lexer.pop(Taxonifi::Splitter::Tokens::Authors)

    authors.names.each do |a|
      n = Taxonifi::Model::Person.new()
      n.last_name = a[:last_name]
      n.initials = a[:initials]
      @builder.people.push n 
    end

    @builder.year   = t.year.to_i
    @builder.parens = t.parens
  end

end
