module Taxonifi

  class RefError < StandardError; end

  module Model
    class Ref < Taxonifi::Model::Base

      ATTRIBUTES = [
        :authors,      # Array of Taxonifi::Model::Person   
        :title, 
        :year,
        :publication,
        :volume,
        :number,
        :pages,
        :pg_start,
        :pg_end,
        :cited_page
      ]

      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)
        @parent = nil
        build(ATTRIBUTES, opts)
        @authors = [] if @authors.nil?
        add_author_year(opts[:author_year]) if !opts[:author_year].nil? && opts[:author_year].size > 0
        true
      end

      def add_author_year(string)
        auth_yr = Taxonifi::Splitter::Builder.build_author_year(string)
        @year = auth_yr.year
        @authors = auth_yr.people
      end

      # Returns a pipe delimited representation of the reference.
      def compact_string
        s = [authors.collect{|a| a.compact_string}.join, year, self.title, publication, volume, number, pages, pg_start, pg_end, cited_page].join("|").downcase.gsub(/\s/, '')
      end

      def compact_author_year_index
        Taxonifi::Model::AuthorYear.new(people: @authors, year: @year).compact_index
      end



    end
  end
end
