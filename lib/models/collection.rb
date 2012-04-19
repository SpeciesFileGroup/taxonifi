module Taxonifi

  class CollectionError < StandardError; end

  module Model

    class Collection
      attr_accessor :by_id_index
      attr_accessor :current_free_id
      
      def initialize(options = {})
        opts = {
          :initial_id => 0
        }.merge!(options)
        @by_id_index = {} 
        @current_free_id = opts[:initial_id]
        true
      end 

      def object_by_id(id)
        @by_id_index[id] 
      end
     
    end
  end

end
