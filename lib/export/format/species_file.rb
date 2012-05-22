
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

    # tblRanks 5/17/2012
    SPECIES_FILE_RANKS = {
      'subspecies' =>              5,
      'species' =>                 10,
      'species subgroup' =>        11,      
      'species group' =>           12,     
      'species series' =>          14,      
      'infragenus' =>              16,  
      'subgenus' =>                18,
      'genus' =>                   20,
      'genus group' =>             22,   
      'subtribe' =>                28,
      'tribe' =>                   30,
      'supertribe' =>              32,  
      'infrafamily' =>             36,   
      'subfamily' =>               38, 
      'subfamily group' =>         39,       
      'family' =>                  40,
      'epifamily' =>               41, 
      'superfamily' =>             42,  
      'superfamily group' =>       44,         
      'subinfraordinal group' =>   45,             
      'infraorder' =>              46,  
      'suborder' =>                8,
      'order' =>                   50,
      'mirorder' =>                51,
      'superorder' =>              52,  
      'magnorder' =>               53, 
      'cohort' =>                  54,
      'supercohort' =>             55,   
      'infraclass' =>              56,  
      'subclass' =>                58,
      'class' =>                   60,
      'superclass' =>              62,  
      'infraphylum' =>             66,   
      'subphylum' =>               68, 
      'phylum' =>                  70,
      'superphylum' =>             72,   
      'infrakingdom' =>            76,   
      'subkingdom' =>              78,  
      'kingdom' =>                 80,
      'superkingdom' =>            82,    
      'life' =>                    90,
      'unknown' =>                 100 
    }

    attr_accessor :name_collection

    MANIFEST = %w{tblTaxa tblRefs tblPeople tblRefAuthors} 

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new
      }.merge!(options)

      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      @name_collection = opts[:nc]
      @author_index = {}
    end 

    def export
      @name_collection.generate_ref_collection
      # (incorrectly) assumes all authors matching on last names are the same Person
      @author_index = @name_collection.ref_collection.unique_authors.inject({}){|hsh, a| hsh.merge!(a.compact_string => a)}
      
      MANIFEST.each do |f|
        send(f)
      end
    end

    # This maps Taxonifi::Name properties to SpeciesFile tblTaxa
    def tblTaxa
      @headers = %w{TaxonNameId TaxonNameStr RankID Name Parens AboveID RefID DataFlags AccessCode NameStatus StatusFlags OriginalGenusID LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each do |n|
          cols = {
            TaxonNameId: n.id,
            TaxonNameStr: n.parent_ids_sf_style,        # closure -> ends with 1 
            RankID: SPECIES_FILE_RANKS[n.rank], 
            Name: n.name,
            Parens: n.parens ? 0 : 1,
            AboveID: n.related_name.nil? ? (n.parent ? n.parent.id : nil) : n.related_name.id,
            RefID: 'todo',
            DataFlags: 0,                               # see http://software.speciesfile.org/Design/TaxaTables.aspx#Taxon, a flag populated when data is reviewed, initialize to zero
            AccessCode: 0,             
            NameStatus: 'todo',                         # 0 (valid, 1, synonym)
            StatusFlags: 'todo',                        # 0: valid; 40000: jr. synonym
            OriginalGenusId: 'todo',                    
            LastUpdate: Time.now(),
            ModifiedBy: 'todo',
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end

      puts @csv_string
    end

    # This maps Taxonifi::Name properties to SpeciesFile tblTaxa
    def tblRefs
      @headers = %w{RefID Title StatedYear ActualYear PubID Notes}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.ref_collection.collection.each_with_index do |r,i|
          cols = {
            RefID: i,
            Title: nil,
            StatedYear: r.year 
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end

      puts @csv_string
    end

    def tblPeople
      @headers = %w{PersonID FamilyName GivenNames GivenInitials Suffix Role Status LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        i = 0
        @author_index.keys.each_with_index do |k,i|
          a = @author_index[k] 
          a.id = i
          cols = {
            PersonID: a.id,
            FamilyName: a.last_name,
            GivenName: a.first_name,
            GivenInitials: a.initials,
            Suffix: a.suffix,
            Role: nil,
            Status: nil,
            LastUpdate: Time.now(),
            ModifiedBy: 'todo'
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      puts @csv_string
    end

    def tblRefAuthors
      @headers = %w{RefID PersonID SeqNum AuthorCount LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        i = 0
        @name_collection.ref_collection.collection.each_with_index do |r,i|
          r.authors.each_with_index do |x,i|
            a = @author_index[x.compact_string] 
            cols = {
              RefID: r.id,
              PersonID: a.id,
              SeqNum: i,
              AuthorCount: r.authors.size,
              LastUpdate: Time.now(),
              ModifiedBy: 'todo'
            }
            csv <<  @headers.collect{|h| cols[h.to_sym]} 
          end
        end
      end
      puts @csv_string
    end

  end
end
