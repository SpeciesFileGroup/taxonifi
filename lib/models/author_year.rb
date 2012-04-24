require File.expand_path(File.join(File.dirname(__FILE__), "../models/base.rb"))

module Taxonifi
  module Model
    class AuthorYear < Taxonifi::Model::Base
      attr_accessor :people, :year, :parens
      def initialize
        @parens = false  # whether this author year blob was parenthesized
        @people = []     # Array of Taxonifi::Model::People
      end
    end
  end
end

