# The accessor accesses!

module Taxonifi
  module Accessor 

    class AccessorError < StandardError; end

    INPUTS = { 
      name_and_heirarchy: {
        complete_match:   true,
        require_columns:  [ ],
        optional_columns: [ ],
      } 
    }

    # UNPUT.key => /lumper/class
    OUTPUTS = { 
     name_and_heirarchy: [ ]
    } 

    class Assesor
      attr_reader :outputs, :inputs
      def initialze(columns)
      end

      def _access_inputs
      end

      def _access_outputs
      end
    end


  end # end Splitter module
end # Taxonifi module

