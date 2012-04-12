
module Taxonifi::Disolver::Tokens

  # Tokens are simple classes that return a regular expression (pattern to match).
  # You should write a test in test_resolver.rb before defining a token.
  # Remember to register tokens in lists at the bottom of this file.

  class Token 
    # this allows access the to class attribute regexp, without using a class variable
    class << self 
      attr_reader :regexp
    end
    
    attr_reader :value, :flag
    def initialize(str)
      @value = str
    end
  end

  class Year < Token
    @regexp = Regexp.new(/\A\s*(\d\d\d\d)\s*/i)
  end

  class LeftParen < Token
    @regexp = Regexp.new(/\A\s*(\()\s*/i)
  end

  class RightParen < Token
    @regexp = Regexp.new(/\A\s*(\))\s*/i)
  end

  class Comma < Token
    @regexp = Regexp.new(/\A\s*(\,)\s*/i)
  end

  class AuthorYear < Token
    attr_reader :authors, :year, :parens
    # This is going to hit just everything, should only be used 
    # in one off when you know you have that string.
    @regexp = Regexp.new(/\A\s*(\(?[^\+\d)]+(\d\d\d\d)?\)?)\s*/i)

    def initialize(str)
      str.strip!
      # check for parens
      if str =~ /\((.*)\)/
        w = $1
        @parens = true
      else
        w = str
        @parens = false
      end
      # check for year
      if w =~ /(\d\d\d\d)\Z/
        @year = $1
        w.gsub!(/\d\d\d\d\Z/, "")
        w.strip!
      end
      w.gsub!(/,\s*\Z/, '')
      @authors = w.strip
      true 
    end
  end

  # See test_disolver_tokens.rb for scope. As with
  # AuthorYear this will match just about anything.
  # If the match breakdown has "doubts" @flag == true
  class Authors < Token
    attr_reader :authors
    @regexp = Regexp.new(/\A\s*([^\d]+)\s*/i)

    def initialize(str)
      @authors = [] 
      str.strip!
      individuals = []

      # We can simplify if there is an "and" or & 
      if str =~ /(\s+and\s+|\&)/i
        l,r = str.split(/\s+and\s+|\s+\&\s+/i, 2)
        individuals << r
        str = l  
      end

      # Break down remaining individuals, do the most obvious matches first
      if str =~ /\.\,\s*|\.;\s*/  # Period, comma for sure means a split
        individuals.unshift str.split(/\.\,\s*|\.;\s*/)
      elsif str =~/[A-Z]\s*[,;]{1}/ # Capital followed by Comma also suggests split
        # Positive look behind (?<= ) FTW 
        individuals.unshift str.split(/(?<=[A-Z])\s*[;,]{1}\s*/) # we split on all commas
      else # looks like a single individual
        individuals.unshift str
        @flag = true
      end
     
      individuals.flatten!

      individuals.each do |i|
        initials = nil
        last_name = nil
        if i =~ /,/
          last_name, initials = i.split(/,/, 2)
        else # space must indicate the split
          last_name, initials = i.split(/\s/, 2)
        end
        
        a = {} 
        a[:last_name] = last_name.strip

        if initials =~ /jr\./i 
          a[:suffix] = "jr"
          initials.gsub!(/jr\./i, '')
        end

        if initials =~ /\s*von\s*/ 
          a[:suffix] = "von" 
          initials.gsub!(/\s*von\s*/, '')
        end
      
        a[:initials] = initials.strip.split(/\s|\./).collect{|v| v.strip} if initials.size > 0

        @authors << a
      end
    end
  end

  class VolumeNumber  < Token
    attr_reader :volume, :number
    @regexp = Regexp.new(/\A\s*((\d+)\s*[:\(]?\s*(\d+)?\)?)\s*/i)

    def initialize(str)
      str.strip 
      str =~ /\A\s*(\d+)\s*[:\(]?\s*(\d+)?\s*/i
      @volume = $1 
      @number = $2
    end
  end

  # !! You must register token lists as symbols in
  # !! Taxonifi::Disolver
  # 
  # Include all tokens in the global_token_list.
  # Tokens are matched in order of the list. If you 
  # re-order an list ensure that unit tests fail.
  # Create an untested list at your own risk, any proposed
  # ordering will be accepted as long as tests pass.

  def self.global_token_list
    [ 
      Taxonifi::Disolver::Tokens::LeftParen,
      Taxonifi::Disolver::Tokens::Year,
      Taxonifi::Disolver::Tokens::Comma,
      Taxonifi::Disolver::Tokens::RightParen,
      Taxonifi::Disolver::Tokens::AuthorYear,
      Taxonifi::Disolver::Tokens::Authors,
      Taxonifi::Disolver::Tokens::VolumeNumber,
    ]   
  end

  def self.volume_number
    [
      Taxonifi::Disolver::Tokens::VolumeNumber
    ]
  end

end
