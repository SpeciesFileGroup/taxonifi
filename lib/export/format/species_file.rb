
# tblTaxa (5/15/2012)
# TaxonNameID
# TaxonNameStr
# RankID
# Name
# Parens
# AboveID
# LikeNameID
# Extinct
# RefID
# NecAuthor
# DataFlags
# AccessCode
# NameStatus
# StatusFlags
# OriginalGenusID
# Distribution
# Ecology
# Comment
# ExpertID
# ExpertReason
# LastUpdate
# ModifiedBy
# CurrentConceptRefID
# LifeZone

module Taxonifi::Export
   class SpeciesFile < Taxonifi::Export::Base

    attr_accessor :name_collection

    @manifest = %w{file1, file2, file3} 

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new
      }.merge!(options)

      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      @name_collection = opts[:nc]
    end 

    def export
      @headers = %W{identifier parent child rank synonyms}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each do |n|
          csv << [n.id, (n.parent ? n.parent.id : nil), n.name, n.rank]
        end
      end
      
      @csv_string
    end

   end
end
