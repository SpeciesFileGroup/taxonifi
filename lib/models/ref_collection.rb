module Taxonifi
  class RefCollectionError < StandardError; end

  module Model

    class RefCollection < Taxonifi::Model::Collection
    
      attr_accessor :row_index
      attr_accessor :author_index # Built on request, keep from ATTRIBUTES

      def initialize(options = {})
        super
        @row_index = []
        @author_index = {}
        true
      end 

      def object_class
        Taxonifi::Model::Ref  
      end
         
      def object_from_row(row_number)
        @row_index[row_number]
      end

      # (Re) Assigns the id of every associated
      def enumerate_authors
        i = 0
        collection.each do |r|
          r.authors.each do |a|
            a.id = i
            i += 1
          end
        end
      end

      def build_author_index
        collection.each do |r|
          @author_index.merge!(r.id => r.authors.collect{|a| a.id ? a.id : -1})
        end
      end




    end
  end

end
