require 'csv'
require 'fileutils'
require 'require_all'

# Everything in Taxonifi is in here.
module Taxonifi

  # Taxonomic ranks. 
  RANKS = %w{
      kingdom
      phylum
      superclass
      class
      subclass
      infraclass
      cohort
      superorder
      order 
      suborder
      infraorder
      superfamily
      family
      subfamily
      tribe
      subtribe
      genus
      subgenus
      species
      subspecies
      variety
  
}

  require_rel 'taxonifi'


  # TODO use **/*.rb syntax

#  %w{splitter assessor export model utils lumper}.each do |dir|
#   Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "**/*.rb") )) do |file|
#     puts file
#     require file
#   end
#  end

#require File.expand_path(File.join(File.dirname(__FILE__), 'splitter/splitter'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'assessor/assessor'))
#require File.expand_path(File.join(File.dirname(__FILE__), 'export/export'))



end
