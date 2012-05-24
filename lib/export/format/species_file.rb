
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
    attr_accessor :genus_names, :species_names, :nomenclator

    # MANIFEST order is important
    MANIFEST = %w{tblTaxa tblRefs tblPeople tblRefAuthors tblGenusNames tblSpeciesNames tblNomenclator tblCites} 

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new,
        :export_folder => 'species_file'
      }.merge!(options)
      super(opts)
      
      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      @name_collection = opts[:nc]
      
      @author_index = {}
     
      # 
      # Careful here, at present we are just generating Reference microcitations from our names, so the indexing "just works"
      # because it's all internal.  There will is a strong potential for key collisions if this pipeline is modified to 
      # include references external to the initialized name_collection. 
      #
      @by_author_reference_index = {}
      @genus_names = {}
      @species_names = {}
      @nomenclator = {}
      
    end 

    def export
      super

      @name_collection.generate_ref_collection
      # (incorrectly) assumes all authors matching on last names are the same Person
      @author_index = @name_collection.ref_collection.unique_authors.inject({}){|hsh, a| hsh.merge!(a.compact_string => a)}

      # See notes in initalize re potential key collisions!
      @by_author_reference_index =  @name_collection.ref_collection.collection.inject({}){|hsh, r| hsh.merge!(r.author_year_index => r)}
      @name_collection.names_at_rank('genus').inject(@genus_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('subgenus').inject(@genus_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('species').inject(@species_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('subspecies').inject(@species_names){|hsh, n| hsh.merge!(n.name => nil)}

      MANIFEST.each do |f|
        write_file(f, send(f))
      end
    end

    def tblTaxa
      @headers = %w{TaxonNameId TaxonNameStr RankID Name Parens AboveID RefID DataFlags AccessCode NameStatus StatusFlags OriginalGenusID LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each do |n|
          ref = @by_author_reference_index[n.author_year_index]
          cols = {
            TaxonNameId: n.id,
            TaxonNameStr: n.parent_ids_sf_style,        # closure -> ends with 1 
            RankID: SPECIES_FILE_RANKS[n.rank], 
            Name: n.name,
            Parens: n.parens ? 0 : 1,
            AboveID: n.related_name.nil? ? (n.parent ? n.parent.id : nil) : n.related_name.id,
            RefID: (ref ? ref.id : nil),
            DataFlags: 0,                                # see http://software.speciesfile.org/Design/TaxaTables.aspx#Taxon, a flag populated when data is reviewed, initialize to zero
            AccessCode: 0,             
            NameStatus: (n.related_name.nil? ? 0 : 7),     # 0 :valid, 7: synonym)
            StatusFlags: (n.related_name.nil? ? 0 : 262144), # 0 :valid, 262144: jr. synonym
            OriginalGenusId: (n.parens ? n.parent_at_rank('genus').id : nil),                     
            LastUpdate: Time.now(),
            ModifiedBy: 'todo',
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
     @csv_string
    end

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
      @csv_string
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
      @csv_string
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
      @csv_string
    end

    def tblCites
      @headers = %w{TaxonNameID SeqNum RefID NomenclatorID LastUpdate ModifiedBy NewNameStatus}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each_with_index do |n,i|
          ref = @by_author_reference_index[n.author_year_index]
          ref_id = ref.id if ref
          cols = {
            TaxonNameID: n.id,
            SeqNum: 1,
            RefID: ref_id,
            NomenclatorID: @nomenclator[n.nomenclator_name], 
            LastUpdate: Time.now(),
            ModifiedBy: "todo",
            NewNameStatus: 0,
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string
    end

    def tblGenusNames
      @csv_string = csv_for_genus_and_species_names_tables('Genus')
      @csv_string
    end

    def tblSpeciesNames
      @csv_string = csv_for_genus_and_species_names_tables('Species')
      @csv_string
    end

    def csv_for_genus_and_species_names_tables(type)
      col = "#{type}NameID"
      @headers = [col, "Name", "LastUpdate", "ModifiedBy", "Italicize"]
      @csv_string = CSV.generate() do |csv|
        csv << @headers 
        var = self.send("#{type.downcase}_names")
        var.keys.each_with_index do |n,i|
          var[n] = i
          cols = {
            col.to_sym => i,
            Name: n,
            LastUpdate: Time.now(),
            ModifiedBy: 'todo',
            Italicize: 1                 # always true for these data
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string 
    end

    # must be called post tblGenusNames and tblSpeciesNames
    def tblNomenclator
      @headers = %w{NomenclatorID GenusNameID SubgenusNameID SpeciesNameID SubspeciesNameID LastUpdate ModifiedBy SuitableForGenus SuitableForSpecies}
      @csv_string = CSV.generate() do |csv|
        csv << @headers
        i = 0
        @name_collection.collection.each do |n|
          next if Taxonifi::RANKS.index(n.rank) < Taxonifi::RANKS.index('genus')
          cols = {
            NomenclatorID: i,
            GenusNameID: @genus_names[n.parent_name_at_rank('genus')],
            SubgenusNameID: @genus_names[n.parent_name_at_rank('subgenus')],
            SpeciesNameID: @species_names[n.parent_name_at_rank('species')],
            SubspeciesNameID: @species_names[n.parent_name_at_rank('subspecies')],
            LastUpdate: Time.now(),   
            ModifiedBy: 'todo',         
            SuitableForGenus: 0,            # Set in SF 
            SuitableForSpecies: 0           # Set in SF
          }
          @nomenclator.merge!(n.nomenclator_name => i)
          i += 1
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string
    end

  end
end
