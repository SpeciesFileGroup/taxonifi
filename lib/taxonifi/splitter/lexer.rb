#
# Lexer taken verbatim from OboParser and other mjy gems.  
#
class Taxonifi::Splitter::Lexer
  attr_reader :input, :token_list
  def initialize(input, token_list = nil)

    raise Taxonifi::Splitter::SplitterError, "Invalid token list passed to Lexer." if (!token_list.nil? && !Taxonifi::Splitter::TOKEN_LISTS.include?(token_list)  )
    token_list = :global_token_list if token_list.nil?

    @input = input
    @token_list = token_list 
    @next_token = nil
  end

  # Checks whether the next token is of the specified class. 
  def peek(token_class, token_list = nil)
    token = read_next_token(token_class)
    return token.class == token_class
  end

  # Return (and delete) the next token from the input stream, or raise an exception
  # if the next token is not of the given class.
  def pop(token_class)
    token = read_next_token(token_class)
    @next_token = nil
    if token.class != token_class
      raise(Taxonifi::Splitter::SplitterError, "expected #{token_class.to_s} but received #{token.class.to_s} at #{@input[0..10]}...", caller)
    else
      return token
    end
  end

  private
  
  # Read (and store) the next token from the input, if it has not already been read.
  def read_next_token(token_class)
    if @next_token
      return @next_token
    else
      # check for a match on the specified class first
      if match(token_class)
        return @next_token
      else
        # now check all the tokens for a match
        Taxonifi::Splitter::Tokens.send(@token_list).each {|t|
          return @next_token if match(t)
        }
      end
      # no match, either end of string or lex-error
      if @input != ''
        raise(Taxonifi::Splitter::SplitterError, "Lexer Error, unknown token at |#{@input[0..20]}...", caller)
      else
        return nil
      end
    end
  end

  # Match a token to the input.
  def match(token_class)
    if (m = token_class.regexp.match(@input))
      @next_token = token_class.new(m[1])
      @input = @input[m.end(0)..-1]
      return true
    else
      return false
    end
  end

end
