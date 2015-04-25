require File.expand_path(File.join(File.dirname(__FILE__), "../model/base.rb"))

module Taxonifi
  module Model
    # A class to aggregate People and Year combinations.
    class AuthorYear < Taxonifi::Model::Base
      # Array of Taxonifi::Model::People
      attr_accessor :people
      # String 
      attr_accessor :year
      # The parens attribute reflects that this combinations was
      # cited in parentheses.
      attr_accessor :parens

      def initialize(options = {})
        opts = {
          :people => [],
          :parens => false,
          :year => nil
        }.merge!(options)

        @parens = opts[:parens] 
        @people = opts[:people] 
        @year = opts[:year] 
      end

      # Return a string representing all data, used in indexing.
      def compact_index
        index = [@year]
        @people.each do |a|
          index.push(a.compact_string)
        end
        index.join("-")
      end
    end
  end
end

