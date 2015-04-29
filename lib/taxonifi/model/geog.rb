module Taxonifi
  class GeogError < TaxonifiError; end
  module Model

    # An instance of some geopolitical unit.
    # Not fully developed yet.
    class Geog < Taxonifi::Model::Base

      # require 'geokit'
      # include Geokit::Geocoders

      GEOG_RANKS = ['country', 'state', 'county']
      ATTRIBUTES = [:name, :rank, :parent]
      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)
        @parent = nil
        build(ATTRIBUTES - [:parent], opts)
        @parent = opts[:parent] if (!opts[:parent].nil? && opts[:parent].class == Taxonifi::Model::Geog)
        true
      end 

      # Set the "rank" of this geographic unit.
      def rank=(rank)
        r = rank.to_s.downcase.strip
        if !GEOG_RANKS.include?(r) 
          raise GeogError, "#{r} is not a valid rank."
        end
        @rank = r
      end

      # Set parent of this rank (also a Taxonifi::Model::Geog instance).
      def parent=(parent)
       if parent.nil?
         raise GeogError, "Parent can't be set to nil in Taxonifi::Model::Geog."
       end

        if @rank.nil?
          raise Taxonifi::GeogError, "Parent of geog can not be set if rank of child is not set." 
        end

        if parent.class != Taxonifi::Model::Geog
          raise GeogError, "Parent is not a Taxonifi::Model::Geog."
        end

        if GEOG_RANKS.index(parent.rank) >= GEOG_RANKS.index(self.rank)
          raise GeogError, "Parent is same or lower rank than self (#{rank})."
        end
        
        @parent = parent
      end

    end
  end
end
