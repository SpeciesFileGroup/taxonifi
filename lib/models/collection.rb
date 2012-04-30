module Taxonifi

  class CollectionError < StandardError; end

  module Model

    class Collection
      attr_accessor :by_id_index
      attr_accessor :current_free_id
      attr_accessor :collection 

      def initialize(options = {})
        opts = {
          :initial_id => 0
        }.merge!(options)
        @collection = []
        @by_id_index = {} 
        @current_free_id = opts[:initial_id]
        true
      end 

      def object_by_id(id)
        @by_id_index[id] 
      end

      def object_class
        Taxonifi::Model::GenericObject
      end

      def add_object(obj)
        raise CollectionError, "Taxonifi::Model::#{object_class.class} not passed to Collection.add_object()." if !(obj.class == object_class)
        raise CollectionError, "Taxonifi::Model::#{object_class.class}#id may not be pre-initialized if used in a Collection." if !obj.id.nil?
        obj.id = @current_free_id
        @current_free_id += 1
        @collection.push(obj)
        @by_id_index.merge!(obj.id => obj)
        return obj.id
      end

      def parent_id_vector(id)
        vector = []
        while !@by_id_index[id].parent.nil? 
          vector.unshift @by_id_index[id].parent.id
          id = @by_id_index[id].parent.id 
        end
        vector
      end



    end
  end

end
