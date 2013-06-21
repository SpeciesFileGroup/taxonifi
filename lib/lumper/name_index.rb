require File.expand_path(File.join(File.dirname(__FILE__), '../taxonifi'))

module Taxonifi::Lumper
  class NameIndex
    attr_accessor :index

    def initialize
      @index = {}
    end

    def new_rank(rank)
      @index[rank] = {}
    end

    def name_exists_at_rank?(name, rank)
      name_index[rank] && name_index[rank][name] 
    end

  end
end

