
module Taxonifi::Export

  # Writes a OBO formatted file for all names in a name collection.
  # !! Does not write synonyms out. 
  # Follows the TTO example.
  class OboNomenclature < Taxonifi::Export::Base

    # See https://phenoscape.svn.sourceforge.net/svnroot/phenoscape/trunk/vocab/taxonomic_rank.obo
    # Site: https://www.phenoscape.org/wiki/Taxonomic_Rank_Vocabulary
    # Values of -1 have no correspondance in that ontology. 
    # Nt all values are supported. Not all values are included.
    TAXRANKS = {
      'taxonomic_rank' =>          0,
      'variety'        =>          16,
      'bio-variety'    =>          32,
      'subspecies' =>              23,
      'form' =>                    26,
      'species' =>                 5,
      'species complex' =>         12,
      'species subgroup' =>        11,      
      'species group' =>           10,     
      'species series' =>          -1,      
      'series'  =>                 31,
      'infragenus' =>              43,  
      'subgenus' =>                9,
      'genus' =>                   5,
      'genus group' =>             -1,   
      'subtribe' =>                28,
      'tribe' =>                   25,
      'supertribe' =>              57,  
      'infrafamily' =>             41,   
      'subfamily' =>               24, 
      'subfamily group' =>         -1,       
      'family' =>                  4,
      'epifamily' =>               -1, 
      'superfamily' =>             18,  
      'superfamily group' =>       -1,         
      'subinfraordinal group' =>   -1,             
      'infraorder' =>              13,  
      'suborder' =>                14,
      'order' =>                   3,
      'mirorder' =>                -1,
      'superorder' =>              20,  
      'magnorder' =>               -1,
      'parvorder' =>               21, 
      'cohort' =>                  -1,
      'supercohort' =>             -1,   
      'infraclass' =>              19,  
      'subclass' =>                7,
      'class' =>                   2,
      'superclass' =>              15,  
      'infraphylum' =>             40,   
      'subphylum' =>               8, 
      'phylum' =>                  1,
      'superphylum' =>             27,   
      'infrakingdom' =>            44,   
      'subkingdom' =>              29,  
      'kingdom' =>                 17,
      'superkingdom' =>            22,    
      'life' =>                    -1,
      'unknown' =>                 -1,
      'section' =>                 30
    }

    attr_accessor :name_collection, :namespace

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new,
        :export_folder => 'obo_nomenclature',
        :starting_id => 1,
        :namespace => 'XYZ'
      }.merge!(options)

      super(opts)
      raise Taxonifi::Export::ExportError, 'NameCollection not passed to OboNomenclature export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      @name_collection = opts[:nc]
      @namespace = opts[:namespace]
      @time = Time.now.strftime("%D %T").gsub('/',":") 
      @empty_quotes = "" 
    end 

    # Writes the file.
    def export()
      super
      f = new_output_file('obo_nomenclature.obo') 
     
      # header 
      f.puts 'format-version: 1.2'
      f.puts "date: #{@time}"
      f.puts 'saved-by: someone'
      f.puts 'auto-generated-by: Taxonifi'
      f.puts 'synonymtypedef: COMMONNAME "common name"'
      f.puts 'synonymtypedef: MISSPELLING "misspelling" EXACT'
      f.puts 'synonymtypedef: TAXONNAMEUSAGE "name with (author year)" NARROW'
      f.puts "default-namespace: #{@namespace}"
      f.puts "ontology: FIX-ME-taxonifi-ontology\n\n" 

      # terms
      @name_collection.collection.each do |n|
        f.puts '[Term]'
        f.puts "id: #{id_string(n)}"
        f.puts "name: #{n.name}"
        f.puts "is_a: #{id_string(n.parent)} ! #{n.parent.name}" if n.parent
        f.puts "property_value: has_rank #{rank_string(n)}"
        f.puts
      end

      # typedefs
      f.puts "[Typedef]"
      f.puts "id: has_rank"
      f.puts "name: has taxonomic rank"
      f.puts "is_metadata_tag: true"

      true
    end

    def rank_string(name)    
      "TAXRANK:#{TAXRANKS[name.rank].to_s.rjust(7,"0")}"
    end

    def id_string(name)
      "#{@namespace}:#{name.id.to_s.rjust(7,"0")}"
    end

  end # End class
end # End module
