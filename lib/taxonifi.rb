require 'csv'

module Taxonifi

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

   Dir.glob( File.expand_path(File.join(File.dirname(__FILE__), "models/*.rb") )) do |file|
     require file
   end

   # an aliase for Taxonifi::Revisor.revise
   #def self.transform(options)
   #  opt = {
   #    :from => nil,
   #    :to => nil
   #  }.merge!(options)
   #  raise if opt[:from].nil? || opt[:to].nil?
   #  Taxonifi::Revisor.revise(opt) 
   #end

end
