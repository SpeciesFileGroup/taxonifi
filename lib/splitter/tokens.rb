
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
        @year = $1.to_i
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
  # If the match breakdown has "doubts" then @flag is set to  true
  # Add exceptions at will, just test using TestSplittTokens#test_authors.
  # TODO: Unicode the [a-z] bits?
  class Authors < Token
    attr_reader :names
    @regexp = Regexp.new(/\A\s*([^\d]+)\s*/i)

    def initialize(input)
      str = input 
      @names = [] 
      str.strip!
      naked_and = false # look for the pattern 'Foo, Bar and Smith', i.e. no initials
      individuals = []
      last_individual = nil

      # We can simplify if there is an "and" or & 
      if str =~ /(\s+and\s+|\&)/i
        l,r = str.split(/\s+\,?\s*and\s+|\s+\&\s+/i, 2) # added \, \s+
        last_individual = r
        str = l  
        naked_and = true
      end

      # Look for an exception case, no initials, "and" or "&" previously present, like:
      #   Foo, Bar and Smith  
      if naked_and && not(str =~ /\./) && str =~ /s*([A-Z][a-z]{1,})\s*\,+\s*([A-Z][a-z]{1,})/ 
        individuals.unshift str.split(/\s*\,\s*/)
        str = nil 
      end

      # Look for an exception case, no period and multiple commas, like:
      #   Foo A, Bar ZA, Smith-Blorf A
      if str && !naked_and && (str.split(",").size > 2) && !(str =~ /\./)
        individuals = str.split(",")
        str = nil
      end

      m1 = Regexp.new(/^\s*((van\s*den)?\s*[A-Z][a-z]+(\-[A-Z][a-z]+)?\s*,\s*(\s*[A-Z](\-[A-Z])?\s*\.\s*){1,}(de la)?(,\s*Jr\.)?(\,\s*von)?)\s*/)
      m2 = Regexp.new(/^\s*(([A-Z]\.\s*){1,}[A-Z][a-z]+),/) 
      # /^\s*(
      #       (van\s*den)?          # Optional prefix
      #       [A-Z][a-z]+           # Capitalized name
      #       (\-[A-Z][a-z]+)?      # Optional dashed name
      #       \s*,\s*               # spaced comma
      #       (\s*[A-Z]             # Initials
      #        (\-[A-Z])?           # Optional dashed initial
      #       \s*\.\s*){1,}         # One or more initials
      #       (de la)?              # Optional post-fixes
      #       (,\s*Jr\.)?
      #       (,\s*von)?
      #       )
      #   /x 
      #     (Watson, T. F.,),
      # /^\s*(([A-Z]\.\s*){1,}[A-Z][a-z]+),/          (R. Watson | R.F. Watson),

      # pick off remaining authors one at a time 
      if str
        parsing = true
        i = 0
        while parsing
          individual = ''
          check_for_more_individuals = false
          [m2, m1].each do |regex|
            if str =~ regex
              individual = $1
              str.slice!(individual)
              str.strip!
              str.slice!(",")
              individuals.push(individual)
              check_for_more_individuals = true # at least once match, keep going
            end
          end

          # puts "[#{individual}] : #{str}"
          if !check_for_more_individuals
            if str && str.size != 0
              individuals.push(str)
              parsing = false
            end
          end

          i += 1
          raise if i > 100
          parsing = false if str.size == 0
        end
      end

      # Note to remember positive look behind (?<= ) for future hax
      # str.split(/(?<=[A-Z])\s*[;,]{1}\s*/, 2)

      individuals.push(last_individual) if !last_individual.nil?

      # At this point we have isolated individuals.  Strategy is to slice out initials and remainder is last name.
      # Initials regex matches any A-B. A. or " A ", "A-B" pattern (including repeats) 
      # TODO: Make a Token
      match_initials = Regexp.new(/(((\s([A-Z](\-[A-Z])?\s?){1,})$)|(([A-Z](\-[A-Z|a-z]\s*)?\.\s*){1,})|(\s([A-Z](\-[A-Z])?\s){1,}))/)

      individuals.flatten!

      suffixes = [
        Regexp.new(/(jr\.)/i),
        Regexp.new(/(von)/i),
        Regexp.new(/(de la)/i),
      ]

      individuals.each do |i|
        a = {}  # new author

        initials = nil
        last_name = nil
        if i =~ match_initials
          initials = $1
          i.slice!(initials)
          i.strip! 
          last_name = i
        else
          last_name = i
        end

        suffixes.each do |s|
          if last_name =~ s
            a[:suffix] = $1
            last_name.slice!(a[:suffix])
            break  # TODO: suffix is single string now, "von Foobar Jr. III" is going to fail
          end
        end

        last_name.gsub!(/\.|\,/, '')

        a[:last_name] = last_name.strip if last_name # "if" not fully tested for consequences
        a[:initials] = initials.strip.split(/\s|\./).collect{|v| v.strip}.select{|x| x.size > 0} if initials && initials.size > 0

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
