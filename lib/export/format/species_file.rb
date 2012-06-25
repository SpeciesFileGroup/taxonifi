
module Taxonifi::Export

  # Dumps tables identical to the existing structure in SpeciesFile.
  # Will only work in the pre Identity world.  Will reconfigure
  # as templates for Jim's work after the fact.
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
    attr_accessor :ref_collection
    attr_accessor :author_index
    attr_accessor :genus_names, :species_names, :nomenclator
    attr_accessor :authorized_user_id, :time

    # MANIFEST order is important
    MANIFEST = %w{tblTaxa tblRefs tblPeople tblRefAuthors tblGenusNames tblSpeciesNames tblNomenclator tblCites} 

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new,
        :export_folder => 'species_file',
        :authorized_user_id => nil
      }.merge!(options)

      super(opts)
      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      raise Taxonifi::Export::ExportError, 'You must provide authorized_user_id for species_file export initialization.' if opts[:authorized_user_id].nil?
      @name_collection = opts[:nc]
      @authorized_user_id = opts[:authorized_user_id]
      @author_index = {}

      # 
      # Careful here, at present we are just generating Reference micro-citations from our names, so the indexing "just works"
      # because it's all internal.  There will is a strong potential for key collisions if this pipeline is modified to 
      # include references external to the initialized name_collection.  See also export_references.
      #
      @by_author_reference_index = {}
      @genus_names = {}
      @species_names = {}
      @nomenclator = {}
      @time = Time.now.strftime("%F %T") 
    end 

    # Export only the ref_collection. Sidesteps the main name-centric exports
    # Note that this still uses the base @name_collection object as a starting reference,
    # it just references @name_collection.ref_collection.  So you can do:
    #   nc = Taxonifi::Model::NameCollection.new
    #   nc.ref_collection = Taxonifi::Model::RefCollection.new
    #   etc.
    def export_references(options = {})
      opts = {
        :starting_ref_id => 0,
        :starting_author_id => 0
      }

      configure_folders
      build_author_index 

      # order matters
      ['tblPeople', 'tblRefs', 'tblRefAuthors', 'sqlRefs' ].each do |t|
        write_file(t, send(t))
      end
    end

    # Assumes names that are the same are the same person. 
    def build_author_index
      @author_index = @name_collection.ref_collection.unique_authors.inject({}){|hsh, a| hsh.merge!(a.compact_string => a)}
    end

    def export()
      super
      @name_collection.generate_ref_collection(1)

      # Give authors unique ids
      @name_collection.ref_collection.uniquify_authors(1)
      build_author_index 

      # See notes in #initalize re potential key collisions!
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
      @headers = %w{TaxonNameID TaxonNameStr RankID Name Parens AboveID RefID DataFlags AccessCode NameStatus StatusFlags OriginalGenusID LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each do |n|
          ref = @by_author_reference_index[n.author_year_index]
          cols = {
            TaxonNameID: n.id,
            TaxonNameStr: n.parent_ids_sf_style,        # closure -> ends with 1 
            RankID: SPECIES_FILE_RANKS[n.rank], 
            Name: n.name,
            Parens: (n.parens ? 1 : 0),
            AboveID: (n.related_name.nil? ? (n.parent ? n.parent.id : 0) : n.related_name.id),   # !! SF folks like to pre-populate with zeros
            RefID: (ref ? ref.id : 0),
            DataFlags: 0,                                # see http://software.speciesfile.org/Design/TaxaTables.aspx#Taxon, a flag populated when data is reviewed, initialize to zero
            AccessCode: 0,             
            NameStatus: (n.related_name.nil? ? 0 : 7),                            # 0 :valid, 7: synonym)
            StatusFlags: (n.related_name.nil? ? 0 : 262144),                      # 0 :valid, 262144: jr. synonym
            OriginalGenusID: (!n.parens && n.parent_at_rank('genus') ? n.parent_at_rank('genus').id : 0),      # SF must be pre-configured with 0 filler (this restriction needs to go)                
            LastUpdate: @time, 
            ModifiedBy: @authorized_user_id,
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string
    end

    # Generate a tblRefs string.
    def tblRefs
      @headers = %w{RefID ActualYear Title PubID  Verbatim}
      @csv_string = CSV.generate(:col_sep => "\t") do |csv|
        csv << @headers  
        @name_collection.ref_collection.collection.each_with_index do |r,i|
          cols = {
            RefID: r.id, #  i + 1,
            Title: (r.title.nil? ? """""" : r.title),
            PubID: 0,                                   # Careful - assumes you have a pre-generated PubID of Zero in there, PubID table is not included in CSV imports
            ActualYear: r.year,
            Verbatim: r.full_citation
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string
    end

    # TODO make a standard transaction wrapper
    def sqlRefs
      sql = [ 'BEGIN TRY', 'BEGIN TRANSACTION']
      @headers = %w{RefID ActualYear Title PubID  Verbatim}
      @name_collection.ref_collection.collection.each_with_index do |r,i|
        cols = {
          RefID: r.id, #  i + 1,
          Title: (r.title.nil? ? """""" : r.title),
          PubID: 0,                                   # Careful - assumes you have a pre-generated PubID of Zero in there, PubID table is not included in CSV imports
          ActualYear: r.year,
          Verbatim: r.full_citation
        }
        sql <<  "INSERT INTO tblRefs (#{@headers.sort.join(",")}) VALUES (#{@headers.sort.collect{|h| "'#{cols[h.to_sym].to_s.gsub(/'/,"''")}'"}.join(",")});"
      end
      sql << ['COMMIT', 'END TRY', 'BEGIN CATCH', 'ROLLBACK', 'END CATCH']
      sql.join("\n") 
    end

    # Generate tblPeople string.
    def tblPeople
      @headers = %w{PersonID FamilyName GivenNames GivenInitials Suffix Role LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @author_index.keys.each_with_index do |k,i|
          a = @author_index[k] 
          # a.id = i + 1
          cols = {
            PersonID: a.id,
            FamilyName: a.last_name,
            GivenName: a.first_name,
            GivenInitials: a.initials_string,
            Suffix: a.suffix,
            Role: 1,                          # authors 
            LastUpdate: @time,
            ModifiedBy: @authorized_user_id
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string
    end

    # Generate tblRefAuthors string.
    def tblRefAuthors 
      @headers = %w{RefID PersonID SeqNum AuthorCount LastUpdate ModifiedBy}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.ref_collection.collection.each do |r| 
          r.authors.each_with_index do |x, i|
            a = @author_index[x.compact_string] 
            cols = {
              RefID: r.id,
              PersonID: a.id,
              SeqNum: i + 1,
              AuthorCount: r.authors.size,
              LastUpdate: @time,
              ModifiedBy: @authorized_user_id
            }
            csv <<  @headers.collect{|h| cols[h.to_sym]} 
          end
        end
      end
      @csv_string
    end

    # Generate tblCites string.
    def tblCites
      @headers = %w{TaxonNameID SeqNum RefID NomenclatorID LastUpdate ModifiedBy NewNameStatus CitePages Note TypeClarification CurrentConcept ConceptChange InfoFlags InfoFlagStatus PolynomialStatus}
      @csv_string = CSV.generate() do |csv|
        csv << @headers  
        @name_collection.collection.each do |n|
          ref = @by_author_reference_index[n.author_year_index]
          next if ref.nil?
          cols = {
            TaxonNameID: n.id,
            SeqNum: 1,
            RefID: ref.id,
            NomenclatorID: @nomenclator[n.nomenclator_name], 
            LastUpdate: @time, 
            ModifiedBy: @authorized_user_id,
            CitePages: """""",        # equates to "" in CSV speak
            NewNameStatus: 0,
            Note: """""",
            TypeClarification: 0,     # We might derive more data from this
            CurrentConcept: 1,        # Boolean, right?
            ConceptChange: 0,         # Unspecified
            InfoFlags: 0,             # 
            InfoFlagStatus: 1,        # 1 => needs review
            PolynomialStatus: 0
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
          var[n] = i + 1
          cols = {
            col.to_sym => i + 1,
            Name: n,
            LastUpdate: @time, 
            ModifiedBy: @authorized_user_id,
            Italicize: 1                              # always true for these data
          }
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end
      end
      @csv_string 
    end

    # must be called post tblGenusNames and tblSpeciesNames
    def tblNomenclator
      @headers = %w{NomenclatorID GenusNameID SubgenusNameID SpeciesNameID SubspeciesNameID LastUpdate ModifiedBy SuitableForGenus SuitableForSpecies InfrasubspeciesNameID InfrasubKind}
      @csv_string = CSV.generate() do |csv|
        csv << @headers
        i = 1
        @name_collection.collection.each do |n|
          next if Taxonifi::RANKS.index(n.rank) < Taxonifi::RANKS.index('genus')
          ref = @by_author_reference_index[n.author_year_index]
          next if ref.nil?
          cols = {
            NomenclatorID: i,
            GenusNameID: @genus_names[n.parent_name_at_rank('genus')] || 0,
            SubgenusNameID: @genus_names[n.parent_name_at_rank('subgenus')] || 0,
            SpeciesNameID: @species_names[n.parent_name_at_rank('species')] || 0,
            SubspeciesNameID: @species_names[n.parent_name_at_rank('subspecies')] || 0,
            InfrasubspeciesNameID: 0,
            InfrasubKind: 0,                          # this might be wrong
            LastUpdate: @time,  
            ModifiedBy: @authorized_user_id, 
            SuitableForGenus: 0,                      # Set in SF 
            SuitableForSpecies: 0                     # Set in SF
          }
          @nomenclator.merge!(n.nomenclator_name => i)
          i += 1
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end

        # TODO: DRY this up with above- but good number of subtle differences exist!?
        @name_collection.combinations.each do |c|
          ref = @by_author_reference_index[c.compact.last.author_year_index]
          next if ref.nil?
          cols = {
            NomenclatorID: i,
            GenusNameID: (c[0] ? c[0].id : 0),
            SubgenusNameID: (c[1] ? c[1].id : 0),
            SpeciesNameID: (c[2] ? c[2].id : 0),
            SubspeciesNameID: (c[3] ? c[3].id : 0),
            InfrasubspeciesNameID: 0,
            InfrasubKind: 0,                          # this might be wrong
            LastUpdate: @time,  
            ModifiedBy: @authorized_user_id, 
            SuitableForGenus: 0,                      # Set in SF 
            SuitableForSpecies: 0                     # Set in SF
          }
          # check!?
          @nomenclator.merge!(c.compact.last.display_name => i)
          i += 1
          csv <<  @headers.collect{|h| cols[h.to_sym]} 
        end

      end
      @csv_string
    end

  end
end
