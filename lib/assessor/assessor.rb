module Taxonifi

  require File.expand_path(File.join(File.dirname(__FILE__), 'base'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'row_assessor'))

  class AssessorError < StandardError; end

  # The assessor assesses!
  # 
  # A work in progress. The idea is to provide
  # a mechanism to assess incoming data to determine
  # what possible outputs (or other operations)
  # are possible.
  module Assessor 

    INPUTS = { 
      name_and_heirarchy: {
      complete_match:   true,
      require_columns:  [ ],
      optional_columns: [ ],
    } 
    }

    # INPUT.key => /lumper/class
    OUTPUTS = { 
      name_and_heirarchy: [ ]
    } 

  end # end Assessor module
end # Taxonifi module

