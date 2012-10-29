module Taxonifi
  class RefError < StandardError; end
  module Model

    # A basic reference object.  
    class Ref < Taxonifi::Model::Base

      # These attributes are set automatically on #new()
      ATTRIBUTES = [
        :authors,     
        :title, 
        :year,
        :publication,
        :volume,
        :number,
        :pages,
        :pg_start,
        :pg_end,
        :cited_page,   
        :full_citation
      ]

      # Array of Taxonifi::Model::Person   
      attr_accessor :authors      
      # String
      attr_accessor :title 
      # String
      attr_accessor :year
      # String
      attr_accessor :publication
      # String
      attr_accessor :volume
      # String
      attr_accessor :number
      # String.  Anything that doesn't fit in a page range.
      attr_accessor :pages
      # String
      attr_accessor :pg_start
      # String
      attr_accessor :pg_end
      # String.  Some specific page(s) of note.
      attr_accessor :cited_page   
      # String. The full text of the citation, as read from input or assigned, not computed from individual components. 
      attr_accessor :full_citation 
      
      # String. Computed index based on existing Ref#authors and Ref#year
      attr_accessor :author_year_index

      # If :author_year is passed it is broken down into People + year. 
      def initialize(options = {})
        opts = {
        }.merge!(options)
        @parent = nil
        build(ATTRIBUTES, opts)
        @authors = [] if @authors.nil?
        raise Taxonifi::RefError, 'If :author_year is provided then authors and year must not be.' if opts[:author_year] && (!opts[:year].nil? || !opts[:authors].nil?)
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
        s
      end

      # Return a by author_year index.
      def author_year_index
        @author_year_index ||= generate_author_year_index
      end

      # (re-) generate the author year index.
      def generate_author_year_index
        @author_year_index = Taxonifi::Model::AuthorYear.new(people: @authors, year: @year).compact_index
      end

      # Return a single String value representing the page
      # data available for this reference.
      def page_string
        str = '' 
        if @pg_start.nil?
          str = [@pages].compact.join
        else
          if @pg_end.nil?
            str = [@pg_start, @pages].compact.join("; ")
          else
            str = ["#{@pg_start}-#{@pg_end}", @pages].compact.join("; ")
          end
        end
        str.strip
      end

    end
  end
end
