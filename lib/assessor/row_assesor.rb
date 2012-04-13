# The accessor accesses!

module Taxonifi
  module Accessor 

    class RowAccessorError < StandardError; end

    class RowAssessor
      attr_reader :lumps # the lumps present in this row

      # Pass a CSV (require "csv") row as read with the following 
      # parameters: 
      #   headers: true
      #   header_converters: :symbol

      def initialze(csv_row)
        cols = []
        cols = csv_row.entries.select{|c,v| !v.nil?}.collect{|c| c[0]}
        @lumps = Taxonifi::Lumper.available_lumps(cols)
      end

    end


  end # end Splitter module
end # Taxonifi module

