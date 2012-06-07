module Taxonifi
  class NameCollectionError < StandardError; end
  module Model

    # A collection of taxonomic names. 
    class NameCollection < Taxonifi::Model::Collection

      attr_accessor :by_name_index
      attr_accessor :ref_collection

      def initialize(options = {})
        super 
        @collection = []
        @by_name_index = {}             # "foo => [1,2,3]"
        Taxonifi::RANKS.inject(@by_name_index){|hsh, v| hsh.merge!(v => {})}
        @by_name_index['unknown'] = {} # unranked names get dumped in here
        @ref_collection = nil
        true
      end 

      def object_class
        Taxonifi::Model::Name
      end

      # Return the highest RANK for which there is no
      # name in this collection.
      def encompassing_rank
        highest = RANKS.size
        @collection.each do |n|
          h = RANKS.index(n.rank)
          highest = h if h < highest
        end
        RANKS[highest - 1]
      end 

      # The names objects in the collection at a rank. 
      # TODO: Should index this on add_object
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
      # Matches against name (string) and parents ("identity")
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

      # Add an individaul name object, indexing it.
      def add_object(obj)
        super
        index_by_name(obj)
        obj
      end

      # Add an individaul name object, without indexing it. 
      def add_object_pre_indexed(obj)
        super
        index_by_name(obj)
        obj
      end

      # Add a Taxonifi::Model::SpeciesName object
      # as individual objects.
      def add_species_name(sn)
        raise "Failed trying to load [#{sn.display_name}]. SpeciesName#genus#parent must be set before using add_species_name." if sn.genus.parent.nil?
        current_parent_id = sn.genus.parent.id 
        sn.names.each do |o|
          o.parent = object_by_id(current_parent_id)
          if id = name_exists?(o)
            cp_id = id 
          else
            add_object(o)
            cp_id = o.id
          end
          current_parent_id = cp_id
        end
        current_parent_id # return the id of the last name created
      end

      # As #add_species_name but do
      # not assign ids to the incoming names
      # TODO: deprecate?
      def add_species_name_unindexed(sn)
        sn.names.each do |o|
          if !name_exists?(o)
            add_object(o)
          end
        end
      end

      # Take the author/years of these names and generate a reference collection.
      # Start the ids assigned to the references with initial_id.
      def generate_ref_collection(initial_id = 0)
        rc = Taxonifi::Model::RefCollection.new(:initial_id => initial_id)
        if collection.size > 0
          uniques = collection.inject({}){|hsh, n| hsh.merge!(n.author_year_string => nil)}.keys.compact
          if  uniques.size > 0
            uniques.sort.each_with_index do |r, i|
              next if r.size == 0
              ref = Taxonifi::Model::Ref.new(:author_year => r)        
              rc.add_object(ref)
            end
          end
        end
        @ref_collection = rc 
      end

      # Assign a reference collection to this name collection. 
      # !! Overwrites existing reference collection, including ones built
      # using generate_ref_collection. 
      def ref_collection=(ref_collection)
        @ref_collection = ref_collection if ref_collection.class == Taxonifi::Model::RefCollection
      end

      protected

      # Index the object by name into the
      # @by_name_index variable (this looks like:
      #  {"Foo bar" => [1,2,93]})
      def index_by_name(obj)
        rank = obj.rank
        rank ||= 'unknown'
        by_name_index[rank][obj.name] ||= [] 
        by_name_index[rank][obj.name].push obj.id 
      end

    end
  end
end
