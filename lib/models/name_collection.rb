module Taxonifi

  class NameCollectionError < StandardError; end

  module Model

    class NameCollection < Taxonifi::Model::Collection

      attr_accessor :by_name_index

      def initialize(options = {})
        super 
        @collection = []
        @by_name_index = {} # "foo => [1,2,3]"
        Taxonifi::RANKS.inject(@by_name_index){|hsh, v| hsh.merge!(v => {})}
        @by_name_index['unknown'] = {} # unranked names get dumped in here
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

      # Returns id of matching existing name
      # or false if there i s no match.
      # Matches against name (string) and parents
      def name_exists?(name = Taxonifi::Model::Name) 
        # Does the name (string) exist? 
        rank = name.rank.downcase 
        rank ||= 'unknown'
        if by_name_index[rank][name.name]
          # Yes, check to see if parents match
          by_name_index[rank][name.name].each do |id|
            vector = parent_id_vector(id)
            vector.pop
            if vector == parent_id_vector(name.parent.id)
              exists = true
              return id
            end
          end
        end 
        false 
      end

      def add_species_name(sn)
        sn.names.each do |o|
          if !name_exists?(o)
            add_object(o)
          end
        end
      end

      # TODO: deprecate?
      def add_species_name_unindexed(sn)
        sn.names.each do |o|
          if !name_exists?(o)
            add_object(o)
          end
        end
      end

      def add_object(obj)
        super
        index_by_name(obj)
        obj
      end

      def add_object_pre_indexed(obj)
        super
        index_by_name(obj)
        obj
      end

      protected

      def index_by_name(obj)
        rank = obj.rank
        rank ||= 'unknown'
        by_name_index[rank][obj.name] ||= [] 
        by_name_index[rank][obj.name].push obj.id 
      end

    end
  end
end
