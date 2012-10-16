module Taxonifi
  class ModelError < StandardError; end
  module Model

    # A base class for all Taxonifi::Models that represent
    # "individuals" (as opposed to collections of indviduals).  
    class Base 
      # The id of this object.
      attr_accessor :id

      # Optionly store the row this came from
      attr_accessor :row_number

      # Optionally store an id representing the original id usef for this record. 
      # Deprecated for :related 
      # attr_accessor :external_id

      # A general purpose hash populable as needed for related metadata
      attr_accessor :related

      def initialize(options = {})
        @related = {}
      end

      # Return an array of the classes derived from the base class.
      # TODO: DRY with collection code.
      def self.subclasses
        classes = []
        ObjectSpace.each_object do |klass|
          next unless Module === klass
          classes << klass if self > klass
        end
        classes
      end

      # Assign on new() all attributes for the ATTRIBUTES 
      # constant in a given subclass. 
      # !! Check validity prior to building.
      def build(attributes, opts)
        attributes.each do |c|
          self.send("#{c}=",opts[c]) if !opts[c].nil?
        end
      end

      def id=(id)
        raise Taxonifi::ModelError, "Base model objects must have Fixnum ids." if !id.nil? && id.class != Fixnum
        @id = id
      end

      # The ids only of ancestors.
      # Immediate ancestor id is in [].last
      def ancestor_ids
        i = 0 # check for recursion
        ids = []
        p = parent 
        while !p.nil?
          ids.unshift p.id
          p = p.parent
          i += 1
          raise Taxonifi::ModelError, "Infite recursion in parent string detected for Base model object #{id}." if i > 100
        end
        ids
      end

      # Ancestor objects for subclasses
      # that have a parent property.
      # TODO: check for parent attributes
      def ancestors
        i = 0 # check for recursion
        ancestors = []
        p = parent 
        while !p.nil?
          ancestors.unshift p
          p = p.parent
          i += 1
          raise Taxonifi::ModelError, "Infite recursion in parent string detected for Base model object #{id.display_name}." if i > 100
        end
        ancestors 
      end

      # Determines identity base ONLY
      # on attributes in ATTRIBUTES.
      def identical?(obj)
        raise Taxonifi::ModelError, "Objects are not comparible." if obj.class != self.class
        self.class::ATTRIBUTES.each do |a|
          next if a == :id # don't compare
          return false if obj.send(a) != self.send(a)
        end
        return true
      end

    end
  end
end
