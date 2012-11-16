
module Taxonifi::Export

  # Dumps tables identical to the existing structure in SpeciesFile.
  # Will only work in the pre Identity world.  Will reconfigure
  # as templates for Jim's work after the fact.
  class Prolog < Taxonifi::Export::Base
    attr_accessor :name_collection
    attr_accessor :ref_collection
    attr_accessor :pub_collection
    attr_accessor :author_index
    attr_accessor :genus_names, :species_names, :nomenclator
    attr_accessor :authorized_user_id, :time
    attr_accessor :starting_ref_id

    def initialize(options = {})
      opts = {
        :nc => Taxonifi::Model::NameCollection.new,
        :export_folder => 'prolog',
        :starting_ref_id => 1,                              # should be configured elsewhere... but
        :manifest => %w{tblPubs tblRefs tblPeople tblRefAuthors tblTaxa tblGenusNames tblSpeciesNames tblNomenclator tblCites} 
      }.merge!(options)

      @manifest = opts[:manifest]

      super(opts)
      raise Taxonifi::Export::ExportError, 'NameCollection not passed to SpeciesFile export.' if ! opts[:nc].class == Taxonifi::Model::NameCollection
      #   raise Taxonifi::Export::ExportError, 'You must provide authorized_user_id for species_file export initialization.' if opts[:authorized_user_id].nil?
      #  @name_collection = opts[:nc]
      #  @pub_collection = {} # title => id
      #  @authorized_user_id = opts[:authorized_user_id]
      #  @author_index = {}
      #  @starting_ref_id = opts[:starting_ref_id]
      #  
      #  # Careful here, at present we are just generating Reference micro-citations from our names, so the indexing "just works"
      #  # because it's all internal.  There will is a strong potential for key collisions if this pipeline is modified to 
      #  # include references external to the initialized name_collection.  See also export_references.
      #  #
      #  # @by_author_reference_index = {}
      #  @genus_names = {}
      #  @species_names = {}
      #  @nomenclator = {}

      @time = Time.now.strftime("%F %T") 
      @empty_quotes = "" 
    end 

    def export()
      super
      configure_folders
      str = ["FOO"]

      write_file('foo.pl', str.join("\n\n"))

      true
    end

  end # End class
end # End module
