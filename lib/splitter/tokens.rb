
module Taxonifi::Splitter::Tokens

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

  # See test_splitter_tokens.rb for scope. As with
  # AuthorYear this will match just about anything.
  # If the match breakdown has "doubts" @flag == true
  # Add exceptions at will, just test using test_authors.
  # TODO: Unicode the [a-z] bits?
  class Authors < Token
    attr_reader :names
    @regexp = Regexp.new(/\A\s*([^\d]+)\s*/i)

    def initialize(str)
      @names = [] 
      str.strip!
      naked_and = false # look for the pattern 'Foo, Bar and Smith', i.e. no initials
      individuals = []

      # We can simplify if there is an "and" or & 
      if str =~ /(\s+and\s+|\&)/i
        l,r = str.split(/\s+and\s+|\s+\&\s+/i, 2)
        individuals << r
        str = l  
        naked_and = true
      end

      # Look for an exception case, no initials, "and" or "&" previously present, like:
      #   Foo, Bar and Smith  
      if naked_and && not(str =~ /\./) && str =~ /s*([A-Z][a-z]{1,})\s*\,+\s*([A-Z][a-z]{1,})/ 
        individuals.unshift str.split(/\s*\,\s*/)
        str = nil 
      end

      # Break down remaining individuals, do the most obvious matches first
      if str =~ /\.\,\s*|\.;\s*/  # Period, comma for sure means a split
        individuals.unshift str.split(/\.\,\s*|\.;\s*/)
      elsif str =~/[A-Z]\s*[,;]{1}/ # Capital followed by Comma also suggests split
        # Positive look behind (?<= ) FTW 
        individuals.unshift str.split(/(?<=[A-Z])\s*[;,]{1}\s*/) # we split on all commas
      elsif str != nil # looks like a single individual
        individuals.unshift str
        @flag = true
      end

      individuals.flatten!

      individuals.each do |i|
        initials = nil
        last_name = nil
        if i =~ /,/
          last_name, initials = i.split(/,/, 2)
        elsif i =~ /s*(\w{1,})\s{1,}([A-Z][a-z]{1,})s*/ # Looks like a "Van Duzen" esque pattern, guess there is just one name
          last_name = i
        else # space must indicate the split
          if i =~ /\s/
            last_name, initials = i.split(/\s/, 2)
          else # TODO: this else not tested
            last_name = i
          end
        end
        
        a = {} 
        a[:last_name] = last_name.strip if last_name # "if" not fully tested for consequences

        if initials =~ /jr\./i 
          a[:suffix] = "jr"
          initials.gsub!(/jr\./i, '')
        end

        if initials =~ /\s*von\s*/ 
          a[:suffix] = "von" 
          initials.gsub!(/\s*von\s*/, '')
        end
      
        a[:initials] = initials.strip.split(/\s|\./).collect{|v| v.strip} if initials && initials.size > 0

        @names << a
      end
    end
  end

  class VolumeNumber  < Token
    attr_reader :volume, :number

    @regexp = Regexp.new(/\A\s*(([^:(]+)\s*[:\(]?\s*([^:)]+)?\)?)\s*/i)
    # @regexp = Regexp.new(/\A\s*((\d+)\s*[:\(]?\s*(\d+)?\)?)\s*/i) <- only digits allowed in this version

    def initialize(str)
      str.strip 
      str =~ /\A\s*([^:(]+)\s*[:\(]?\s*([^:)]+)?\)?\s*/i
      @volume = $1
      @number = $2
      @volume && @volume.strip!
      @number && @number.strip!
    end
  end

  class Pages < Token
    attr_reader :pg_start, :pg_end, :remainder
    @regexp = Regexp.new(/\A\s*((\d+)\s*[-]?\s*(\d+)?\)?\s*[\.\,]?(.*)?)/i)

    def initialize(str)
      str.strip 
      str =~ /\A\s*(\d+)\s*[-]?\s*(\d+)?\)?\s*[\.\,]?(.*)?/i
      @pg_start = $1 
      @pg_end = $2
      @remainder = $3
    end
  end

  # Matches: 
  # Foo
  # Foo (Bar)
  # Foo (Bar) stuff
  # Foo (Bar) stuff things
  # Foo stuff
  # Foo stuff things
  # TODO: This will likley erroroneously match on authors names that are uncapitalized, e.g.:
  #   Foo stuff von Helsing, 1920
  class Quadrinomial < Token
    attr_reader :genus, :subgenus, :species, :subspecies
    @regexp = Regexp.new(/\A\s*(([A-Z][^\s]+)\s*(\([A-Z][a-z]+\))?\s?([a-z][^\s]+)?\s?([a-z][^\s]+)?)\s*/)

    def initialize(str)
      str.strip 
      str =~ /\A\s*([A-Z][^\s]+)\s*(\([A-Z][a-z]+\))?\s?([a-z][^\s]+)?\s?([a-z][^\s]+)?\s*/i
      @genus = $1 
      @subgenus = $2
      @species = $3
      @subspecies = $4

      if @subgenus =~ /\((.*)\)/
        @subgenus = $1
      end
    end
  end

  # !! You must register token lists as symbols in
  # !! Taxonifi::Splitter
  # 
  # Include all tokens in the global_token_list.
  # Tokens are matched in order of the list. If you 
  # re-order an list ensure that unit tests fail.
  # Create an untested list at your own risk, any proposed
  # ordering will be accepted as long as tests pass.

  def self.global_token_list
    [ 
      Taxonifi::Splitter::Tokens::Quadrinomial,
      Taxonifi::Splitter::Tokens::LeftParen,
      Taxonifi::Splitter::Tokens::Year,
      Taxonifi::Splitter::Tokens::Comma,
      Taxonifi::Splitter::Tokens::RightParen,
      Taxonifi::Splitter::Tokens::AuthorYear,
      Taxonifi::Splitter::Tokens::Authors,
      Taxonifi::Splitter::Tokens::VolumeNumber,
      Taxonifi::Splitter::Tokens::Pages,
    ]   
  end

  def self.volume_number
    [
      Taxonifi::Splitter::Tokens::VolumeNumber
    ]
  end

  def self.pages
    [
      Taxonifi::Splitter::Tokens::Pages
    ]
  end

  def self.species_name
    [
      Taxonifi::Splitter::Tokens::Quadrinomial,
      Taxonifi::Splitter::Tokens::AuthorYear,
    ]
  end



end
