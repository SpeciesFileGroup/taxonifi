# An implementation of the parser/lexer/token pattern by Krishna Dole which in turn was based on
# Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library

#== Outstanding issues:
# * 

module Taxonifi
  module Splitter

    TOKEN_LISTS = [
      :global_token_list,
      :volume_number
    ]

    class SplitterError < StandardError; end

    require File.expand_path(File.join(File.dirname(__FILE__), 'tokens'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'parser'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'lexer'))

    # Load all models
    #  TODO: perhaps use a different scope that doesn't require loading all at once
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "model/*.rb") )) do |file|
      require file
    end

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
  Taxonifi::Splitter::Parser.new(lexer, builder).parse_file
  Taxonfi::Splitter::Parser.new(lexer, builder).foo 
  return builder.bar
end

