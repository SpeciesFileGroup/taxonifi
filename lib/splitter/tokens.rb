#
# Tokens are simple classes that return a regular expression (pattern to match).
# You should write a test in test_resolver.rb before defining a token.
# Remember to register tokens in lists at the bottom of this file.
#
module Taxonifi::Splitter::Tokens

  class Token 
    # This allows access the to class attribute regexp, without using a class variable
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

  # A token to match an author year combination, breaks
  # the string into three parts.
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

  # Complex breakdown of author strings. Handles
  # a wide variety of formats.   
  # See test_splitter_tokens.rb for scope. As with
  # AuthorYear this will match just about anything when used alone.
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

      # Look for an exception case, no periods and multiple commas, like:
      #   Foo A, Bar ZA, Smith-Blorf A
      if str && !naked_and && (str.split(",").size > 2) && !(str =~ /\./)
        individuals = str.split(",")
        str = nil
      end

      prefix = ['van den ', 'Van ', "O'", "Mc", 'Campos ', 'Costa ']
      pre_reg = prefix.collect{|p| "(#{Regexp.escape(p)})?"}.join

      postfix = ['de la', 'von', 'da', 'van', ', Jr.'] 
      post_reg = postfix.collect{|p| "(#{Regexp.escape(p)})?"}.join

      # Initials second
      m1 = Regexp.new(/^\s*(#{pre_reg}             # legal prefix words, includes space if present
                            [A-Z][a-z]+            # a captialized Name 
                            (\-[A-Z][a-z]+)?       # optional dashed addition
                            \s*,\s*                # required comma
                            (\s*                   #  initials, optionally surrounded by whitescape
                             (\-)?                 # optional preceeding dash, hits second initials 
                             [A-Z]                 # required capital initial
                             (\-)?                 # optional initial dash   
                             (\-[A-Z])?            # optional dashed initial
                            \s*\.                  # required period
                            \s*)              
                            {1,}                   # repeat initials as necessary
                            #{post_reg})           # optional legal postfixes
                        \s*/x)

      # Initials first
      m2 = Regexp.new(/^\s*(([A-Z]\.\s*){1,}#{pre_reg}[A-Z][a-z]+#{post_reg}),/)  #  (R. Watson | R.F. Watson),

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
      individuals.flatten!

      # At this point we have isolated individuals.  Strategy is to slice out initials and remainder is last name.
      # Initials regex matches any A-B. A. or " A ", "A-B" pattern (including repeats) 
      # TODO: Make a Token
      match_initials = Regexp.new(/(((\s((\-)?[A-Z](\-[A-Z])?\s?){1,})$)|(((\-)?[A-Z](\-[A-Z|a-z]\s*)?\.\s*){1,})|(\s((\-)?[A-Z](\-[A-Z])?\s){1,}))/)

      # TODO: merge with pre/postfix list
      suffixes = [
        Regexp.new(/\s(van)\s?/i),
        Regexp.new(/\s(jr\.)/i),
        Regexp.new(/\s(von)\s?/i),
        Regexp.new(/\s(de la)\s?/i),
        Regexp.new(/\s(da)\s?/i),
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

        suffix = [] 
        suffixes.each do |s| # .collect{|p| Regexp.escape(p)}.each do |s|
          if last_name =~ s
            t = $1 
            suffix.push(t) 
            last_name.slice!(t)
          end
        end
        a[:suffix] = suffix.join(" ") if suffix.size > 0 

        last_name.gsub!(/\.|\,/, '')

        a[:last_name] = last_name.strip if last_name # "if" not fully tested for consequences
        a[:initials] = initials.strip.split(/\s|\./).collect{|v| v.strip}.select{|x| x.size > 0} if initials && initials.size > 0

        @names << a
      end
    end
  end

  # A token to match volume-number combinations, with various possible formats.
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

  # A token to match page ranges, with remainders noted. 
  class Pages < Token
    attr_reader :pg_start, :pg_end, :remainder
    @regexp = Regexp.new(/\A\s*((\d+)\s*[-]?\s*(\d+)?\)?\s*[\.\,]?(.*)?)/i)

    def initialize(str)
      str.strip 
      str =~ /\A\s*(\d+)\s*[-]?\s*(\d+)?\)?\s*[\.\,]?(.*)?/i
      @pg_start = $1 
      @pg_end = $2
      @remainder = $3.strip
    end
  end

  # A token to match quadrinomial.s
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
  
    # Makes use of negative look ahead for a a period ( (?!\.) ) at the end of a word bounder (\b). 
    @regexp = Regexp.new(/\A\s*(([A-Z][^\s]+\w)\s*(\([A-Z][a-z]+\))?\s?([a-z][^\s]+(?!\.))?\s?([a-z][^\s]*(?!\.)\b)?)\s*/)

    def initialize(str)
      str.strip 
      str =~ /\A\s*([A-Z][^\s]+\w)\s*(\([A-Z][a-z]+\))?\s?([a-z][^\s]+(?!\.))?\s?([a-z][^\s]*(?!\.)\b)?\s*/i
      @genus = $1 
      @subgenus = $2
      @species = $3
      @subspecies = $4

      if @subgenus =~ /\((.*)\)/
        @subgenus = $1
      end
    end
  end
  
  # A token to match variety 
  # Matches: 
  # var. blorf
  # v. blorf
  class Variety < Token
    attr_reader :variety
    @regexp = Regexp.new(/\A\s*((var\.\s*|v\.\s*)(\w+))/i)
    def initialize (str)
      str =~ Regexp.new(/\A\s*(var\.\s*|v\.\s*)(\w+)/i)
      @variety = $2
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
  
  # All tokens.  Order matters!
  def self.global_token_list
    [ 
      Taxonifi::Splitter::Tokens::AuthorYear,
      Taxonifi::Splitter::Tokens::Quadrinomial,
      Taxonifi::Splitter::Tokens::Variety,
      Taxonifi::Splitter::Tokens::LeftParen,
      Taxonifi::Splitter::Tokens::Year,
      Taxonifi::Splitter::Tokens::Comma,
      Taxonifi::Splitter::Tokens::RightParen,
      Taxonifi::Splitter::Tokens::Authors,
      Taxonifi::Splitter::Tokens::VolumeNumber,
      Taxonifi::Splitter::Tokens::Pages,
    ]   
  end

  # Tokens used in breaking down volume/number ranges.
  def self.volume_number
    [
      Taxonifi::Splitter::Tokens::VolumeNumber
    ]
  end

  # Tokens used in breaking down page ranges.
  def self.pages
    [
      Taxonifi::Splitter::Tokens::Pages
    ]
  end

  # Tokens used in breaking down species names.
  # Order matters.
  def self.species_name
    [
      Taxonifi::Splitter::Tokens::AuthorYear,
      Taxonifi::Splitter::Tokens::Quadrinomial,
      Taxonifi::Splitter::Tokens::Variety
    ]
  end

end
