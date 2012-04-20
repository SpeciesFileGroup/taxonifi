module Taxonifi

  class NameCollectionError < StandardError; end

  module Model

    class NameCollection < Taxonifi::Model::Collection

      def initialize(options = {})
        super 
        @collection = []
        true
      end 

      def object_class
        Taxonifi::Model::Name
      end

      # The highest RANKS for which there is no
      # name.
      def encompassing_rank
        highest = RANKS.size
        @collection.each do |n|
          h = RANKS.index(n.rank)
          highest = h if h < highest
        end
        RANKS[highest - 1]
      end 

      # Should index this on add_object
      def names_at_rank(rank)
        raise if !RANKS.include?(rank)
        names = []
        @collection.each do |n|
          names << n if n.rank == rank
        end
        names
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
