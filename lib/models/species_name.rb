module Taxonifi

  class SpeciesNameError < StandardError; end

  module Model

    # The species name model is just a pointer to 5 TaxonifiNames.  The various metadata (author, year, original combination) is stored with the individual 
    # instances of those names.

    class SpeciesName < Taxonifi::Model::Base

      ATTRIBUTES = [:genus, :subgenus, :species, :subspecies, :parent]
      attr_accessor :genus, :subgenus, :species, :subspecies, :parent  # Taxonifi::Name objects (?)

      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)
        build(ATTRIBUTES, opts)
        true
      end 

      def genus=(genus)
        @genus = genus
      end

      def subgenus=(subgenus)
        raise Taxonifi::SpeciesNameError, "Species name must have a Genus name before subgenus can be assigned" if @genus.nil?
        @subgenus = subgenus
      end

      def species=(species)
        raise Taxonifi::SpeciesNameError, "Species name must have a Genus name before species can be assigned" if @genus.nil?
        @species = species 
      end

      def subspecies=(subspecies)
        raise Taxonifi::SpeciesNameError, "Subspecies name must have a species name before species can be assigned" if @species.nil?
        @subspecies = subspecies 
      end

      def parent=(parent)
        if @rank.nil?
          raise Taxonifi::SpeciesNameError, "Parent of name can not be set if rank of child is not set." 
        end

        if parent.class != Taxonifi::Model::Name
          raise NameError, "Parent is not a Taxonifi::Model::Name."
        end

        if parent.rank.nil? ||  (Taxonifi::Ranks.index('genus') > Taxonifi::Ranks.index(parent.rank))
          raise Taxonifi::SpeciesNameError, "Parents of SpeciesNames must have rank higher than Genus."
        end

        @parent = parent
      end

      def names
        ATTRIBUTES.collect{|a| self.send(a)}.compact 
      end

      def display_name
        strs = [] 

        self.names.each do |n|
          case n.rank
          when 'subgenus'
            strs.push "(#{n.name})"
          else
            strs.push n.name 
          end
        end
        strs.push self.names.last.author_year
        txt = strs.compact.join(" ")  
        txt
      end
    end
  end
end

