module Taxonifi

  # An implementation of the parser/lexer/token pattern by Krishna Dole which in turn was based on
  # Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library, which has evolved
  # into mjy's obo_parser/nexus_parser libraries.
  module Splitter

    TOKEN_LISTS = [
      :global_token_list,
      :volume_number,
      :pages,
      :species_name
    ]

    class SplitterError < StandardError; end

    # stub, we might not need
    class Splitter
      def initialize 
        true
      end
    end

  end # end Splitter module
end # Taxonifi module


#= Implementation

def do_bar(input)
  @input = input
  raise(Taxonifi::Splitter::SplitterError, "Nothing passed to parse!") if !@input || @input.size == 0

  builder = Taxonifi::Splitter::SplitterBuilder.new
  lexer = Taxonifi::Splitter::Lexer.new(@input)
  Taxonfi::Splitter::Parser.new(lexer, builder).foo 
  return builder.bar
end

