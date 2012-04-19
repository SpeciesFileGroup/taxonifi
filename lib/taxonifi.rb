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


    # an aliase for Taxonifi::Revisor.revise
    def self.transform(options)
      opt = {
        :from => nil,
        :to => nil
      }.merge!(options)
      raise if opt[:from].nil? || opt[:to].nil?
      Taxonifi::Revisor.revise(opt) 
    end

end
