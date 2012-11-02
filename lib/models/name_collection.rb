module Taxonifi
  class NameCollectionError < StandardError; end
  module Model

    # A collection of taxonomic names. 
    class NameCollection < Taxonifi::Model::Collection

      # A by-name (string index) 
      attr_accessor :by_name_index
     
      # A Taxonifi::Model::RefCollection, optionally generated from Author/Year strings 
      attr_accessor :ref_collection

      # An optional collection of existing combinations of species names, as represented by 
      # individual arrays of Taxonifi::Model::Names.  Note you can not use a Taxonifi::Model::SpeciesName 
      # for this purpose because getting/setting names therin will affect other combinations
      attr_accessor :combinations

      def initialize(options = {})
        super 
        @by_name_index = {'genus_group' => {}, 'species_group' => {} }                 # "foo => [1,2,3]"
         Taxonifi::RANKS[0..-5].inject(@by_name_index){|hsh, v| hsh.merge!(v => {})}  # Lumping species and genus group names 

        @by_name_index['unknown'] = {} # unranked names get dumped in here
        @ref_collection = nil
        @combinations = [] 
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
      # or false if there is no match.
      # !! assumes parent is set
      # Matches against name, year, and all parents (by id).
      # 
      # !! nominotypic names are considered to be the same (species and generic).  See 
      #   @combinations to instantiate these
      #
      # TODO: This is likely already overly ICZN flavoured.
      def name_exists?(name = Taxonifi::Model::Name) 
        # species/genus group names are indexed for indexing purposes 
        rank = name.index_rank

        if by_name_index[rank][name.name_author_year_string]
          by_name_index[rank][name.name_author_year_string].each do |id|
            full_parent_vector = parent_id_vector(name.parent.id) 
            return id if full_parent_vector == parent_id_vector(id)  # this hits species/genus group names
            
            vector = parent_id_vector(id)
            next if vector.last != name.parent.id                    # can stop looking at this possiblity
            vector.pop                                               # compare just parents
            if vector == full_parent_vector 
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

      # Return an array of the names in the collection
      def name_string_array
        collection.collect{|n| n.display_name}
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
     
      # Return an Array of Generic "Homonyms"
      def homonyms_at_rank(rank) 
       raise if !RANKS.include?(rank)
        uniques = {}
        names_at_rank(rank).each do |n|
          uniques[n.name] ||= []
          uniques[n.name].push n
        end
        uniques
      end

      protected

      # Index the object by name into the
      # @by_name_index variable (this looks like:
      #  {"Foo bar" => [1,2,93]})
      #  Pass a Taxonifi::Name
      def index_by_name(name)
        rank = name.rank
        rank = 'species_group' if %w{species subspecies variety}.include?(rank)
        rank = 'genus_group' if %w{genus subgenus}.include?(rank)
        rank ||= 'unknown'

        by_name_index[rank][name.name_author_year_string] ||= [] 
        by_name_index[rank][name.name_author_year_string].push name.id 
      end
    end

  end
end
