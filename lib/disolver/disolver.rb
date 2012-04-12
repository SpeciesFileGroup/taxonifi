# An implementation of the parser/lexer/token pattern by Krishna Dole which in turn was based on
# Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library

#== Outstanding issues:
# * 

module Taxonifi
  module Disolver

    TOKEN_LISTS = [
      :global_token_list,
      :volume_number
    ]

    class DisolverError < StandardError; end

    require File.expand_path(File.join(File.dirname(__FILE__), 'tokens'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'parser'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'lexer'))

    # Load all models
    #  TODO: perhaps use a different scope that doesn't require loading all at once
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "model/*.rb") )) do |file|
      require file
    end

    # stub, we might not need
    class Disolver
      def initialize 
        true
      end
    end

  end # end Disolver module
end # Taxonifi module


#= Implementation

def do_bar(input)
  @input = input
  raise(Taxonifi::Disolver::DisolverError, "Nothing passed to parse!") if !@input || @input.size == 0

  builder = Taxonifi::Disolver::DisolverBuilder.new
  lexer = Taxonifi::Disolver::Lexer.new(@input)
  Taxonifi::Disolver::Parser.new(lexer, builder).parse_file
  Taxonfi::Disolver::Parser.new(lexer, builder).foo 
  return builder.bar
end

