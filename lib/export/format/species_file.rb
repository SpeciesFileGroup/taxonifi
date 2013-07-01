
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
      'suborder' =>                48,
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
    attr_accessor :pub_collection
    attr_accessor :author_index
    attr_accessor :genus_names, :species_names, :nomenclator
    attr_accessor :authorized_user_id, :time

    attr_accessor :built_nomenclators

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new,
        :export_folder => 'species_file',
        :authorized_user_id => nil,
        :manifest => %w{tblPubs tblRefs tblPeople tblRefAuthors tblTaxa tblGenusNames tblSpeciesNames tblNomenclator tblCites tblTypeSpecies}  
      }.merge!(options)

      @manifest = opts[:manifest]

      super(opts)
      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      raise Taxonifi::Export::ExportError, 'You must provide authorized_user_id for species_file export initialization.' if opts[:authorized_user_id].nil?
      @name_collection = opts[:nc]
      @pub_collection = {} # title => id
      @authorized_user_id = opts[:authorized_user_id]
      @author_index = {}

      # Careful here, at present we are just generating Reference micro-citations from our names, so the indexing "just works"
      # because it's all internal.  There will is a strong potential for key collisions if this pipeline is modified to 
      # include references external to the initialized name_collection.  See also export_references.
      #
      # @by_author_reference_index = {}
      @genus_names = {}
      @species_names = {}
      @nomenclator = {}

      @time = Time.now.strftime("%F %T") 
      @empty_quotes = "" 
    end 

    # Assumes names that are the same are the same person. 
    def build_author_index
      @author_index = @name_collection.ref_collection.unique_authors.inject({}){|hsh, a| hsh.merge!(a.compact_string => a)}
    end

    def export()
      super
      # You must have
      # how to create and link the reference IDs.

      # Reference related approaches:
      # 
      # @name_collection.generate_ref_collection(1)
      # Give authors unique ids:
      # @name_collection.ref_collection.uniquify_authors(1) 

      if @name_collection.ref_collection 
        build_author_index
      end

      # raise Taxonifi::Export::ExportError, 'NameCollection has no RefCollection, you might try @name_collection.generate_ref_collection(1), or alter the manifest: hash.' if ! @name_collection.ref_collection.nil?

      # See notes in #initalize re potential key collisions!
      # @by_author_reference_index =  @name_collection.ref_collection.collection.inject({}){|hsh, r| hsh.merge!(r.author_year_index => r)}

      @name_collection.names_at_rank('genus').inject(@genus_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('subgenus').inject(@genus_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('species').inject(@species_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('subspecies').inject(@species_names){|hsh, n| hsh.merge!(n.name => nil)}
      @name_collection.names_at_rank('variety').inject(@species_names){|hsh, n| hsh.merge!(n.name => nil)}

      # Add combinations of names from nomenclators/citations as well

      @name_collection.nomenclators.keys.each do |k|
        @genus_names.merge!(@name_collection.nomenclators[k][0] => nil)
        @genus_names.merge!(@name_collection.nomenclators[k][1] => nil)
        @species_names.merge!(@name_collection.nomenclators[k][2] => nil)
        @species_names.merge!(@name_collection.nomenclators[k][3] => nil)
        @species_names.merge!(@name_collection.nomenclators[k][4] => nil)
      end

      @genus_names.delete_if{|key,value| key.nil? || key.length == 0}
      @species_names.delete_if{|key,value| key.nil? || key.length == 0}

 
      str = [ 'BEGIN TRY', 'BEGIN TRANSACTION']
      @manifest.each do |f|
        str << send(f)
      end
      str << ['COMMIT', 'END TRY', 'BEGIN CATCH', 
              'SELECT ERROR_LINE() AS ErrorLine, ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;', 
              'ROLLBACK', 'END CATCH']  
      write_file('everything.sql', str.join("\n\n"))
      true
    end

    # Deprecated!
    # Export only the ref_collection. Sidesteps the main name-centric exports
    # Note that this still uses the base @name_collection object as a starting reference,
    # it just references @name_collection.ref_collection.  So you can do:
    #   nc = Taxonifi::Model::NameCollection.new
    #   nc.ref_collection = Taxonifi::Model::RefCollection.new
    #   etc.
    def export_references(options = {})
      raise Taxonifi::Export::ExportError, 'Method deprecated, alter manifest to achieve a similar result.'
      #configure_folders
      #build_author_index 

      ## order matters
      #['tblPeople', 'tblRefs', 'tblRefAuthors', 'sqlRefs' ].each do |t|
      #  write_file(t, send(t))
      #end
    end

    # Gets the reference for a name as referenced
    # by .properties[:link_to_ref_from_row]
    def get_ref(name)
#     if not name.properties[:link_to_ref_from_row].nil?
#       return @name_collection.ref_collection.object_from_row(name.properties[:link_to_ref_from_row])
#     end
#     nil
      name.original_description_reference ? name.original_description_reference : nil
    end

    def tblTaxa
      @headers = %w{TaxonNameID TaxonNameStr RankID Name Parens AboveID RefID DataFlags AccessCode Extinct NameStatus StatusFlags OriginalGenusID LastUpdate ModifiedBy}
      sql = []

      # Need to add by rank for FK constraint handling

      Taxonifi::RANKS.each do |rank|
        @name_collection.names_at_rank(rank).each do |n|
          $DEBUG && $stderr.puts("#{n.name} is too long") if n.name.length > 30

          # ref = get_ref(n) 
          cols = {
            TaxonNameID: n.id,
            TaxonNameStr: n.parent_ids_sf_style,                       # closure -> ends with 1 
            RankID: SPECIES_FILE_RANKS[n.rank], 
            Name: n.name,
            Parens: (n.parens ? 1 : 0),
            AboveID: (n.related_name.nil? ? (n.parent ? n.parent.id : 0) : n.related_name.id),   
            RefID: (n.original_description_reference ? n.original_description_reference.id : 0),
            DataFlags: 0,                  # see http://software.speciesfile.org/Design/TaxaTables.aspx#Taxon, a flag populated when data is reviewed, initialize to zero
            AccessCode: 0,             
            Extinct: (n.properties && n.properties['extinct'] == 'true' ? 1 : 0), 
            NameStatus: (n.related_name.nil? ? 0 : 7),                            # 0 :valid, 7: synonym)
            StatusFlags: (n.related_name.nil? ? 0 : 262144),                      # 0 :valid, 262144: jr. synonym
            OriginalGenusID: (n.properties && !n.properties['original_genus_id'].nil? ? n.properties['original_genus_id'] : 0),      # SF must be pre-configured with 0 filler (this restriction needs to go)                
            LastUpdate: @time, 
            ModifiedBy: @authorized_user_id,
          }
          sql << sql_insert_statement('tblTaxa', cols) 
        end
      end
      sql.join("\n")
    end

    # Generate a tblRefs string.
    def tblRefs
      sql = []
      @headers = %w{RefID ActualYear Title PubID Verbatim}
      @name_collection.ref_collection.collection.each_with_index do |r,i|
        # Assumes the 0 "null" pub id is there
        pub_id = @pub_collection[r.publication] ? @pub_collection[r.publication] : 0

        # Build a note based on "unused" properties
        note = [] 
        if r.properties
          r.properties.keys.each do |k|
            note.push "#{k}: #{r.properties[k]}" if r.properties[k] && r.properties.length > 0
          end 
        end
        note = note.join("; ") 
        note = @empty_quotes if note.length == 0

        cols = {
          RefID: r.id,
          ContainingRefID: 0,
          Title: (r.title.nil? ? @empty_quotes : r.title),
          PubID: pub_id,  
          Series: @empty_quotes,
          Volume: (r.volume ? r.volume : @empty_quotes),
          Issue:  (r.number ? r.number : @empty_quotes),
          RefPages: r.page_string, # always a strings
          ActualYear: (r.year ? r.year : @empty_quotes),
          StatedYear: @empty_quotes,
          AccessCode: 0,
          Flags: 0, 
          Note: note, 
          LastUpdate: @time,
          LinkID: 0,
          ModifiedBy: @authorized_user_id,
          CiteDataStatus: 0,
          Verbatim: (r.full_citation ? r.full_citation : @empty_quotes)
        }
        sql << sql_insert_statement('tblRefs', cols) 
      end
      sql.join("\n")
    end

    # Generate tblPubs SQL
    def tblPubs
      sql = []
      @headers = %w{PubID PrefID PubType ShortName FullName Note LastUpdate ModifiedBy Publisher PlacePublished PubRegID Status StartYear EndYear BHL}

      # Hackish should build this elsewhere, but degrades OK
      pubs = @name_collection.ref_collection.collection.collect{|r| r.publication}.compact.uniq

      pubs.each_with_index do |p, i|
        cols = {
          PubID: i + 1,
          PrefID: 0,
          PubType: 1,
          ShortName: "unknown_#{i}", # Unique constraint
          FullName: p,
          Note: @empty_quotes,
          LastUpdate: @time, 
          ModifiedBy: @authorized_user_id,
          Publisher: @empty_quotes,
          PlacePublished: @empty_quotes,
          PubRegID: 0,
          Status: 0, 
          StartYear: 0, 
          EndYear: 0, 
          BHL: 0
        }
        @pub_collection.merge!(p => i + 1)
        sql << sql_insert_statement('tblPubs', cols) 
      end
      sql.join("\n")
    end

    # Generate tblPeople string.
    def tblPeople
      @headers = %w{PersonID FamilyName GivenNames GivenInitials Suffix Role LastUpdate ModifiedBy}
      sql = []   
      @author_index.keys.each_with_index do |k,i|
        a = @author_index[k] 
        # a.id = i + 1
        cols = {
          PersonID: a.id,
          FamilyName: (a.last_name.length > 0 ? a.last_name : "Unknown"),
          GivenNames: a.first_name || @empty_quotes,
          GivenInitials: a.initials_string || @empty_quotes,
          Suffix: a.suffix || @empty_quotes,
          Role: 1,                          # authors 
          LastUpdate: @time,
          ModifiedBy: @authorized_user_id
        }
        sql << sql_insert_statement('tblPeople', cols) 
      end
      sql.join("\n")
    end

    # Generate tblRefAuthors string.
    def tblRefAuthors 
      @headers = %w{RefID PersonID SeqNum AuthorCount LastUpdate ModifiedBy}
      sql = []
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
          sql << sql_insert_statement('tblRefAuthors', cols) 
        end
      end
      sql.join("\n")
    end

    # Generate tblCites string.
    def tblCites
      @headers = %w{TaxonNameID SeqNum RefID NomenclatorID LastUpdate ModifiedBy NewNameStatus CitePages Note TypeClarification CurrentConcept ConceptChange InfoFlags InfoFlagStatus PolynomialStatus}
      sql = []

      @name_collection.citations.keys.each do |name_id|
        seq_num = 1 
        @name_collection.citations[name_id].each do |ref_id, nomenclator_index, properties|
          cols = {
            TaxonNameID:       name_id,
            SeqNum:            seq_num,
            RefID:             ref_id,
            NomenclatorID:     nomenclator_index,
            LastUpdate:        @time, 
            ModifiedBy:        @authorized_user_id,
            CitePages:         (properties[:cite_pages] ? properties[:cite_pages] : @empty_quotes),
            NewNameStatus:     0,
            Note:              (properties[:note] ? properties[:note] : @empty_quotes),
            TypeClarification: 0,     # We might derive more data from this
            CurrentConcept:    (properties[:current_concept] == true ? 1 : 0),     # Boolean, right?
            ConceptChange:     0,     # Unspecified
            InfoFlags:         0,     # 
            InfoFlagStatus:    1,     # 1 => needs review
            PolynomialStatus:  0
          }
          sql << sql_insert_statement('tblCites', cols) 
          seq_num += 1
        end
      end
      sql.join("\n")
    end

    # Generate tblTypeSpecies string.
    def tblTypeSpecies
      @headers = %w{GenusNameID SpeciesNameID Reason AuthorityRefID FirstFamGrpNameID LastUpdate ModifiedBy NewID}
      sql = []

      names = @name_collection.names_at_rank('genus') + @name_collection.names_at_rank('subgenus')
      names.each do |n|
        if n.properties[:type_species_id]
          ref = get_ref(n)

          # ref = @by_author_reference_index[n.author_year_index]
          next if ref.nil?
          cols = {
            GenusNameID: n.id ,
            SpeciesNameID: n.properties[:type_species_id],
            Reason: 0            ,
            AuthorityRefID: 0    ,
            FirstFamGrpNameID: 0 ,
            LastUpdate: @time    ,
            ModifiedBy: @authorized_user_id   ,
            NewID: 0 # What is this?  
          }
          sql << sql_insert_statement('tblTypeSpecies', cols) 
        end
      end
      sql.join("\n")
    end 
   
    def tblGenusNames
      # TODO: SF tests catch unused names based on some names not being included in Nomeclator data.  We could optimize so that the work around is removed.
      # I.e., all the names get added here, not all the names get added to Nomclator/Cites because of citations which are not original combinations
      sql = sql_for_genus_and_species_names_tables('Genus')
      sql 
    end

    def tblSpeciesNames
      # TODO: SF tests catch unused names based on some names not being included in Nomeclator data.  We could optimize so that the work around is removed.
      # I.e., all the names get added here, not all the names get added to Nomclator/Cites because of citations which are not original combinations
      sql = sql_for_genus_and_species_names_tables('Species')
      sql 
    end

    def sql_for_genus_and_species_names_tables(type)
      sql = []
      col = "#{type}NameID"
      @headers = [col, "Name", "LastUpdate", "ModifiedBy", "Italicize"]
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
        sql << sql_insert_statement("tbl#{type}Names", cols) 
      end
      sql.join("\n")
    end

    # Must be called post tblGenusNames and tblSpeciesNames.
    # Some records are not used but can be cleaned by SF 
    def tblNomenclator
      @headers = %w{NomenclatorID GenusNameID SubgenusNameID SpeciesNameID SubspeciesNameID LastUpdate ModifiedBy SuitableForGenus SuitableForSpecies InfrasubspeciesNameID InfrasubKind}
      sql = []   
      i = 1

      # Ugh, move build from here 
      @name_collection.nomenclators.keys.each do |i|
        name =  @name_collection.nomenclators[i]
        genus_id = @genus_names[name[0]]
        genus_id ||= 0
        subgenus_id = @genus_names[name[1]]
        subgenus_id ||= 0
        species_id = @species_names[name[2]]
        species_id ||= 0
        subspecies_id = @species_names[name[3]]
        subspecies_id ||= 0
        variety_id = @species_names[name[4]]
        variety_id ||= 0

        cols = {
          NomenclatorID: i,
          GenusNameID: genus_id, 
          SubgenusNameID: subgenus_id, 
          SpeciesNameID: species_id, 
          SubspeciesNameID: subspecies_id,
          InfrasubspeciesNameID: variety_id,
          InfrasubKind: (variety_id == 0 ? 0 : 2), 
          LastUpdate: @time,  
          ModifiedBy: @authorized_user_id, 
          SuitableForGenus: 0,                      # Set in SF w test
          SuitableForSpecies: 0                     # Set in SF w test
        }
        i += 1
        sql << sql_insert_statement('tblNomenclator', cols) 
      end

      sql.join("\n")
    end



  end # End class
end # End module
