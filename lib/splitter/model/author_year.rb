
module Taxonifi::Splitter::Model

    class AuthorYear
      attr_accessor :author, :year, :parens
      def initialize
        @parens = false
      end
    end

    class AuthorYearBuilder
      def initialize
        @o = AuthorYear.new
      end

      # def add_term(tags)
      #   @of.terms.push OboParser::Term.new(tags)
      # end

      # def add_typedef(tags)
      #   @of.typedefs.push OboParser::Typedef.new(tags)
      # end

      def author_year
        @o 
      end
    end

end # Taxonifi module

