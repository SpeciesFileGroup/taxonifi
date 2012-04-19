module Taxonifi
  module Model
    class AuthorYear
      attr_accessor :people, :year, :parens
      def initialize
        @parens = false  # whether this author year blob was parenthesized
        @people = []     # Array of Taxonifi::Model::People
      end
    end
  end
end

