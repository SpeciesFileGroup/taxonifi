
module Taxonifi::Export

  # Writes a OBO formatted file for all names in a name collection.
  # !! Does not write synonyms out. 
  # Follows the TTO example.
  class OboNomenclature < Taxonifi::Export::Base

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
