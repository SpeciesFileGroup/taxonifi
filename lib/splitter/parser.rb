class Taxonifi::Splitter::Parser
  def initialize(lexer, builder )
    @lexer = lexer
    @builder = builder
  end

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

    @builder.year   = t.year.to_i
    @builder.parens = t.parens
  end

  def parse_species_name
    t = @lexer.pop(Taxonifi::Splitter::Tokens::Quadrinomial)
    ranks = %w{genus subgenus species subspecies}
    names = {} 
    last_parent = nil
    ranks.each do |r|
      names.merge!(r: nil)
      @builder.send("#{r}=", Taxonifi::Model::Name.new(:name => t.send(r), rank: r) ) if t.send(r)
    end

    if @lexer.peek(Taxonifi::Splitter::Tokens::AuthorYear)
      t = @lexer.pop(Taxonifi::Splitter::Tokens::AuthorYear)
      @builder.names.last.author = t.authors
      @builder.names.last.year = t.year
      @builder.names.last.parens = !t.parens
    end
  
    @builder
  end

end
