module Taxonifi

  class NameCollectionError < StandardError; end

  module Model

    class NameCollection < Taxonifi::Model::Collection

      attr_reader :names
      
      def initialize(options = {})
        super 
        @names = []
        true
      end 

      # Method also indexes names
      def add_name(name)
        raise NameCollectionError, "Taxonifi::Model::Name not passed to NameCollection.add_name." if !(name.class == Taxonifi::Model::Name)
        raise NameCollectionError, "Taxonifi::Model::Name#id may not be pre-initialized if used in a NameCollection." if !name.id.nil?

        name.id = @current_free_id
        @current_free_id += 1

        @names.push(name)

        @by_id_index.merge!(name.id => name)
        return name.id
      end

      # The highest RANKS for which there is no
      # name.
      def encompassing_rank
        highest = RANKS.size
        @names.each do |n|
          h = RANKS.index(n.rank)
          highest = h if h < highest
        end
        RANKS[highest - 1]
      end 

      # Should index this on add_name
      def names_at_rank(rank)
        raise if !RANKS.include?(rank)
        names = []
        @names.each do |n|
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
