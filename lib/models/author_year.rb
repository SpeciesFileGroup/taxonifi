require File.expand_path(File.join(File.dirname(__FILE__), "../models/base.rb"))

module Taxonifi
  module Model
    class AuthorYear < Taxonifi::Model::Base
      attr_accessor :people, :year, :parens
      def initialize(options = {})
        opts = {
          :people => [],
          :parens => false,
          :year => nil
        }.merge!(options)

        @parens = opts[:parens] # whether this author year blob was parenthesized
        @people = opts[:people] # Array of Taxonifi::Model::People
        @year = opts[:year] 
      end

      def compact_index
        index = [@year]
        @people.each do |a|
          index.push a.compact_string
        end
        index.join("-")
      end

    end
  end
end

