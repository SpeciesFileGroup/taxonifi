require_rel 'shared_class_methods'

module Taxonifi
  module Model

    # A base class for all Taxonifi::Models that represent
    # "individuals" (as opposed to collections of indviduals).
    class Base

      include Taxonifi::Model::SharedClassMethods

      # The id of this object.
      attr_accessor :id

      # Optionly store the row this came from
      attr_accessor :row_number

      # A general purpose Hash populable as needed for related metadata
      attr_accessor :properties

      # TODO: Rethink this. See @@ATTRIBUTES in subclasses.
      ATTRIBUTES = [:row_number]

      def initialize(options = {})
        @properties = {}
      end

      # Assign on new() all attributes for the ATTRIBUTES
      # constant in a given subclass.
      # !! Check validity prior to building.
      def build(attributes, opts)
        attributes.each do |c|
          self.send("#{c}=",opts[c]) if !opts[c].nil?
        end
      end

      # Add a set of properties (doesn't check for key collisions)
      def add_properties(hash)
        @properties.merge!(hash)
      end

      # Add a key/value pair to @properties
      def add_property(key, value)
        if @properties[key]
          return false
        else
          @properties.merge!(key => value)
        end
      end

      # Replace an existing key/value pair in @properties
      def replace_property(key,value)
       if !@properties[key]
        return false
       else
        @properties.merge!(key => value)
       end
      end

      # Delete an existing key/value pair in @properties
      def delete_property(key)
       if !@properties[key]
         @properties.delete(key)
       else
        @properties.merge!(key => value)
       end
      end

      def id=(id)
        raise Taxonifi::ModelError, "Base model objects must have Fixnum ids." if !id.nil? && id.class != ::Integer
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
    end

  end
end
