module Taxonifi
  class GeogCollectionError < StandardError; end
  module Model

    # Collection of geog objects.
    # TODO: Consider moving the row index to the base collection (those this doesn't
    # always make sense).
    class GeogCollection < Taxonifi::Model::Collection
      attr_accessor :row_index

      def initialize(options = {})
        super
        @row_index = []
        true
      end 

      # Return the object represented by a row.
      def object_from_row(row_number)
        @row_index[row_number]
      end

      def object_class
        Taxonifi::Model::Geog
      end
    
    end
  end
end
