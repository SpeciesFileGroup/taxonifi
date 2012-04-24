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
        true
      end

      # Returns a pipe delimited representation of the reference.
      def compact_string
        s = [authors.collect{|a| a.compact_string}.join, year, self.title, publication, volume, number, pages, pg_start, pg_end,  cited_page].join("|").downcase.gsub(/\s/, '')
      end

    end
  end
end
