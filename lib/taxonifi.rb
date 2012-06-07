require 'csv'

# Everything in Taxonifi is in here.
module Taxonifi

  # Taxonomic ranks. 
  RANKS = %w{
      kingdom
      phylum
      class
      infraclass
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
  }


  require File.expand_path(File.join(File.dirname(__FILE__), 'lumper/lumper'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'splitter/splitter'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'assessor/assessor'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'export/export'))

  Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "models/*.rb") )) do |file|
    require file
  end

end
