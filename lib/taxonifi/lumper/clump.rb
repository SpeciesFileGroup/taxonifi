# require File.expand_path(File.join(File.dirname(__FILE__), '../taxonifi'))

# A Clump is a "C"ollection of lump derivatives and the relationships between these derivatives!
# It's used to define relationships among objects derived, for example, between single rows of data
module Taxonifi::Lumper:Clumps

  class Taxonifi::Lumper::Clump

    attr_accessor :collections 
    attr_accessor :annonymous_collection_index
    attr_accessor :csv

    def initialize(csv = nil)
      @collections = {}
      @annonymous_collection_index = 0
      @csv = csv if !csv.nil?
      @csv ||= nil
    end

    def add_csv(csv)
      if @csv.nil?
        @csv = csv
      else
        return false
      end
    end

    def remove_csv
      if !@csv.nil?
        @csv = nil 
        true
      else
        false
      end
    end

    def get_from_csv(options = {})
      opts = {
        collection: :name
      }.merge!(options) 
      raise if @csv.nil?
      raise if not Taxonifi::Model::Collection.subclass_prefixes.include?(opts[:collection].to_s)

      case opts[:collection]
      when :name
        add_name_collection(opts)
      when :ref
        add_ref_collection(opts)
      else
        raise
      end
    end 

    def next_available_collection_name
      "collection#{annonymous_collection_index}"
    end

    def increment_annonymous_collection_index
      @annonymous_collection_index += 1
      true
    end  

    def add_ref_collection(options)
      opts = {
        :name => next_available_collection_name
      }.merge!(options)
      if   add_collection(opts[:name],Taxonifi::Model::RefCollection.new(opts))
        increment_annonymous_collection_index if (opts[:name] == next_available_collection_name)
        true
      else
        false
      end
    end

    def add_name_collection(options)
      opts = {
        :name => next_available_collection_name
      }.merge!(options)
      if add_collection(opts[:name],Taxonifi::Model::NameCollection.new(opts))
        increment_annonymous_collection_index if opts[:name] == next_available_collection_name
        true
      else
        false 
      end
    end

    def add_collection(name = nil, collection = nil)
      return false if (name.nil? || collection.nil?)
      return false if @collections.keys.include?(name)
      @collections.merge!(name => collection)
    end


    def link(collection1, collection2, link_method)

    end

    def self.link_name_collection_and_ref_collection(options = {})
      opt = {
        :nc => Taxonifi::Model::NameCollection.new,
        :rc => Taxonifi::Model::RefCollection.new,
        :by => :row_number
      }
    end

    # Should ultimately make this a reddis hook

    # variable indecies b/w data


  end 
end
