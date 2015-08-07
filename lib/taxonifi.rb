require 'csv'
require 'fileutils'
require 'require_all'

# Everything in Taxonifi is in here.
module Taxonifi

  class TaxonifiError < StandardError; end;

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

end
