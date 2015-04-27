module Taxonifi
  class SpeciesNameError < StandardError; end
  module Model

    # The species name model is just a pointer to 5 Taxonifi::Model::Names. 
    # The various metadata (author, year, original combination) is stored with the individual 
    # instances of those names.
    # Taxonifi::Model::Names have no ids!  

    class SpeciesName < Taxonifi::Model::Base
      ATTRIBUTES = [:genus, :subgenus, :species, :subspecies, :variety, :parent]
      ATTRIBUTES.each do |a|
        attr_accessor a
      end

      def initialize(options = {})
        opts = {
        }.merge!(options)
        build(ATTRIBUTES, opts)
        true
      end 

      # Create a new SpeciesName from a string format
      # TODO: Is this replicated somewhere else?
      # Examples: 
      #   Taxonifi::Model::SpeciesName.new_from_string('Aus bus Smith, 1920')
      #   Taxonifi::Model::SpeciesName.new_from_string('Aus (Cus) bus dus (Smith, 1920)')
      def self.new_from_string(name)
        raise Taxonifi::SpeciesNameError, "No name passed to SpeciesName.new_from_string" if name.nil? || name.length == 0 
        #  Appears to be a validly formatted species epithet at this point.
        lexer = Taxonifi::Splitter::Lexer.new(name, :species_name)
        builder = Taxonifi::Model::SpeciesName.new
        Taxonifi::Splitter::Parser.new(lexer, builder).parse_species_name
        builder
      end

      # Set the genus name.
      def genus=(genus)
        @genus = genus
      end

      # Set the subgenus name.
      def subgenus=(subgenus)
        raise Taxonifi::SpeciesNameError, "Species name must have a Genus name before subgenus can be assigned" if @genus.nil?
        @subgenus = subgenus
        @subgenus.parent = @genus
      end

      # Set the species name.
      def species=(species)
        raise Taxonifi::SpeciesNameError, "Species name must have a Genus name before species can be assigned" if @genus.nil?
        @species = species 
        @species.parent = (@subgenus ? @subgenus : @genus)
      end

      # Set the subspecies name.
      def subspecies=(subspecies)
        raise Taxonifi::SpeciesNameError, "Subspecies name must have a species name before species can be assigned" if @species.nil?
        @subspecies = subspecies 
        @subspecies.parent = @species
      end

      # Set the variety name.
      def variety=(variety)
        raise Taxonifi::SpeciesNameError, "Varieties name must have a species name before variety can be assigned" if @species.nil? 
        @variety = variety 
        @variety.parent = (@subspecies ? @subspecies : @species)
      end

      # Set the parent name.
      def parent=(parent)
        if parent.class != Taxonifi::Model::Name
          raise SpeciesNameError, "Parent is not a Taxonifi::Model::Name."
        end

        if parent.rank.nil? ||  (Taxonifi::RANKS.index('genus') <= Taxonifi::RANKS.index(parent.rank))
          raise Taxonifi::SpeciesNameError, "Parents of SpeciesNames must have rank higher than Genus."
        end

        @parent = parent
      end

      # Return an array of Name objects.
      def names
        ATTRIBUTES.collect{|a| self.send(a)}.compact 
      end

      # Return a string representation of the species name.
      # Becuase we build parent relationships on setters
      # this is the same as the last names display_name
      def display_name
        names.last.display_name 
      end

      # Returns true if this combination contains a nominotypic subspecies name 
      def nominotypical_species?
        names.species && names.subspecies && (names.species.name == names.subspecies.name)
      end

      # Returns true if this combinations contains a nominotypic subgenus 
      def nominotypical_genus?
        names.genus && names.subgenus && (names.genus.name == names.subgenus.name)
      end

    end
  end
end

