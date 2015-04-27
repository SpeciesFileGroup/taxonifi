require 'csv'
require 'fileutils'

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

 require File.expand_path(File.join(File.dirname(__FILE__), 'splitter/splitter'))
 require File.expand_path(File.join(File.dirname(__FILE__), 'assessor/assessor'))
 require File.expand_path(File.join(File.dirname(__FILE__), 'export/export'))

  # TODO use **/*.rb syntax
  %w{model utils lumper}.each do |dir|
    Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "#{dir}/*.rb") )) do |file|
      require file
    end
  end


end
