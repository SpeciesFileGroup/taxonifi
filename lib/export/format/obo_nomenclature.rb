
module Taxonifi::Export

  # Dumps tables identical to the existing structure in SpeciesFile.
  # Will only work in the pre Identity world.  Will reconfigure
  # as templates for Jim's work after the fact.
  class OboNomenclature < Taxonifi::Export::Base

    # tblRanks 5/17/2012
    TAXRANKS = {
      'subspecies' =>              0,
      'species' =>                 0,
      'species subgroup' =>        0,      
      'species group' =>           0,     
      'species series' =>          0,      
      'infragenus' =>              0,  
      'subgenus' =>                0,
      'genus' =>                   0,
      'genus group' =>             0,   
      'subtribe' =>                0,
      'tribe' =>                   0,
      'supertribe' =>              0,  
      'infrafamily' =>             0,   
      'subfamily' =>               0, 
      'subfamily group' =>         0,       
      'family' =>                  4,
      'epifamily' =>               0, 
      'superfamily' =>             0,  
      'superfamily group' =>       0,         
      'subinfraordinal group' =>   0,             
      'infraorder' =>              0,  
      'suborder' =>                0,
      'order' =>                   0,
      'mirorder' =>                0,
      'superorder' =>              0,  
      'magnorder' =>               0, 
      'cohort' =>                  0,
      'supercohort' =>             0,   
      'infraclass' =>              0,  
      'subclass' =>                0,
      'class' =>                   0,
      'superclass' =>              0,  
      'infraphylum' =>             0,   
      'subphylum' =>               0, 
      'phylum' =>                  0,
      'superphylum' =>             0,   
      'infrakingdom' =>            0,   
      'subkingdom' =>              0,  
      'kingdom' =>                 0,
      'superkingdom' =>            82,    
      'life' =>                    90,
      'unknown' =>                 100 
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
      @time = Time.now.strftime("%F %T") 
      @empty_quotes = "" 
    end 

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

        # typedefs

        f.puts "[Typedef]"
        f.puts "id: has_rank"
        f.puts "name: has taxonomic rank"
        f.puts "is_metadata_tag: true"

      end
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
