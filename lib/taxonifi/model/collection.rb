module Taxonifi
  class CollectionError < TaxonifiError; end
  module Model

    require File.expand_path(File.join(File.dirname(__FILE__), 'shared_class_methods'))

    # The base class that all collection classes are derived from.
    class Collection
      include Taxonifi::Model::SharedClassMethods

      # A Hash indexing object by id like {Integer => SomeBaseSubclass} 
      attr_accessor :by_id_index

      # A Integer representing the current free id to be used for an accessioned a collection object. Not used in non-indexed collections.
      attr_accessor :current_free_id

      # An Array, the collection.
      attr_accessor :collection 

      # Returns an array of (downcased) strings representing the prefixes of the Collection based subclasses, like
      # ['name', 'geog', 'ref'] etc.
      def self.subclass_prefixes
        self.subclasses.collect{|c| c.to_s.split("::").last}.collect{|n| n.gsub(/Collection/, "").downcase}
      end

      def initialize(options = {})
        opts = {
          :initial_id => 0
        }.merge!(options)
        raise CollectionError, "Can not start with an initial_id of nil." if opts[:initial_id].nil?
        @collection = []
        @by_id_index = {} 
        # @by_row_index = {}
        @current_free_id = opts[:initial_id]
        true
      end 

      # Define the default class. Over-ridden in 
      # specific collections. 
      def object_class
        Taxonifi::Model::GenericObject
      end

      # Return an object in this collection by id.
      def object_by_id(id)
        @by_id_index[id] 
      end

      # Add an object to the collection. 
      def add_object(obj)
        raise CollectionError, "Taxonifi::Model::#{object_class.class}#id may not be pre-initialized if used with #add_object, consider using #add_object_pre_indexed." if !obj.id.nil?
        object_is_allowed?(obj)
        obj.id = @current_free_id.to_i
        @current_free_id += 1
        @collection.push(obj)
        @by_id_index.merge!(obj.id => obj) 
        return obj
      end

      # Add an object without setting its ID. 
      def add_object_pre_indexed(obj)
        object_is_allowed?(obj)
        raise CollectionError, "Taxonifi::Model::#{object_class.class} does not have a pre-indexed id." if obj.id.nil?
        @collection.push(obj)
        @by_id_index.merge!(obj.id => obj)
        return obj
      end

      # Return an array of ancestor (parent) ids.
      # TODO: deprecate?
      # More or less identical to Taxonifi::Name.ancestor_ids except
      # this checks against the indexed names in the collection
      # rather than Name->Name relationships
      # The two should be identical in all(?) conievable cases
      def parent_id_vector(id = Fixnum)
        vector = []
        return vector if @by_id_index[id].nil? || @by_id_index[id].parent.nil?
        id = @by_id_index[id].parent.id
        while !id.nil?
          vector.unshift id
          if @by_id_index[id].parent
            id = @by_id_index[id].parent.id 
          else
            id = nil
          end
        end
        vector
      end

      # Returns an Array which respresents
      # all the "root" objects.
      # TODO: test
      def objects_without_parents
        @collection.select{|o| o.parent.nil?}
      end

      # Returns an Array of immediate children
      # TODO: test 
      def children_of_object(o)
        @collection.select{|i| i.parent == o}
      end

      protected

      # Check to see that the object can be added to this collection.
      def object_is_allowed?(obj)
        raise CollectionError, "Taxonifi::Model::#{object_class.class} not passed to Collection.add_object()." if !(obj.class == object_class)
        true
      end

    end
  end

end
