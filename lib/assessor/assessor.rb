# The assessor assesses!

module Taxonifi
  module Assessor 

    require File.expand_path(File.join(File.dirname(__FILE__), 'row_assessor'))

    class AssessorError < StandardError; end

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

      def _assess_inputs
      end

      def _assess_outputs
      end
    end


  end # end Splitter module
end # Taxonifi module

